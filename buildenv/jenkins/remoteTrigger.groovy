#!groovy

// Triggers a single job on the remote 'temurin-compliance' Jenkins (via the Parameterized Remote Trigger plugin),
// passing parameters supplied in the PARAMETERS_JSON job parameter.
//
// Job parameters:
//   REMOTE_JOB_NAME : name of the remote job to trigger
//   PARAMETERS_JSON : parameters for the remote job. Either a JSON object, e.g.
//                       {"SDK_RESOURCE": "customized", "PLATFORMS": "aarch64_mac"}
//                     or the Groovy/Java map string format, e.g.
//                       {SDK_RESOURCE=customized, PLATFORMS=aarch64_mac}

def REMOTE_JOB_NAME = (params.REMOTE_JOB_NAME ?: "").trim()
def PARAMETERS_JSON = (params.PARAMETERS_JSON ?: "").trim()

if (!REMOTE_JOB_NAME) {
    error "REMOTE_JOB_NAME must be specified"
}
if (!PARAMETERS_JSON) {
    error "PARAMETERS_JSON must be specified"
}

// Helper function to update build result to worst status
// Priority: ABORTED > FAILURE > UNSTABLE > SUCCESS
def updateBuildResult(newResult) {
    def resultPriority = ['ABORTED': 4, 'FAILURE': 3, 'UNSTABLE': 2, 'SUCCESS': 1, 'NOT_BUILT': 0]
    def currentPriority = resultPriority[currentBuild.result] ?: 0
    def newPriority = resultPriority[newResult] ?: 0

    if (newPriority > currentPriority) {
        echo "Updating build result from ${currentBuild.result} to ${newResult}"
        currentBuild.result = newResult
    }
}

// Helper function to get a badge URL for a given build result status.
// Uses the local Jenkins embeddable-build-status-plugin endpoint so the badge
// is served from "this" Jenkins instance (no remote credentials required).
def getResultBadgeUrl(result) {
    def statusMap = [
        'SUCCESS'   : [text: 'passing',  color: 'brightgreen'],
        'UNSTABLE'  : [text: 'unstable', color: 'yellow'],
        'FAILURE'   : [text: 'failing',  color: 'red'],
        'ABORTED'   : [text: 'aborted',  color: 'lightgrey'],
        'NOT_BUILT' : [text: 'not_run',  color: 'lightgrey']
    ]
    def entry = statusMap[result] ?: [text: 'unknown', color: 'lightgrey']
    return "${env.JENKINS_URL}buildStatus/icon?status=${entry.text}&color=${entry.color}"
}

// Parse PARAMETERS_JSON into a Map<String, String>.
// Accepts a JSON object, or the "{KEY=value, KEY2=value2}" map string format.
def parseParameters(String text) {
    def result = [:]
    if (!text.startsWith('{') || !text.endsWith('}')) {
        error "PARAMETERS_JSON must be enclosed in { }"
    }

    def parsedJson = null
    try {
        parsedJson = readJSON(text: text)
    } catch (Exception e) {
        echo "PARAMETERS_JSON is not valid JSON, parsing as key=value map string"
    }

    if (parsedJson != null) {
        parsedJson.each { k, v ->
            result[k.toString()] = (v == null || v.toString() == 'null') ? '' : v.toString()
        }
    } else {
        // Strip enclosing braces and split on commas that are followed by "KEY=",
        // so that commas inside values do not break the parse.
        def body = text.substring(1, text.length() - 1).trim()
        if (body) {
            body.split(/,\s*(?=[A-Za-z_][A-Za-z0-9_]*=)/).each { entry ->
                int idx = entry.indexOf('=')
                if (idx < 1) {
                    error "Unable to parse parameter entry '${entry}', expected KEY=value"
                }
                result[entry.substring(0, idx).trim()] = entry.substring(idx + 1).trim()
            }
        }
    }
    return result
}

timestamps {
    def parsedParams = parseParameters(PARAMETERS_JSON)
    if (!parsedParams) {
        error "No parameters could be parsed from PARAMETERS_JSON"
    }

    // If PIPELINE_DISPLAY_NAME is not supplied, build it from: REMOTE_JOB_NAME : JDK_VERSION : PLATFORM : TARGET
    // (only including the values that are present)
    def displayName = parsedParams['PIPELINE_DISPLAY_NAME']
    if (!displayName) {
        displayName = [REMOTE_JOB_NAME, parsedParams['JDK_VERSION'], parsedParams['PLATFORM'], parsedParams['TARGET']]
            .findAll { it }.join(' : ')
    }
    currentBuild.setDisplayName("#${currentBuild.number} - ${displayName}")
    currentBuild.description = (currentBuild.description) ? currentBuild.description + "<br>" : ""

    echo "Triggering remote job ${REMOTE_JOB_NAME} with parameters:"
    parsedParams.each { k, v -> echo "  ${k}: ${v}" }

    // Convert all values to String to avoid Boolean cast errors
    def paramList = parsedParams.collect { k, v ->
        MapParameter(name: k.toString(), value: v.toString())
    }

    // Trigger remote job
    def handle = triggerRemoteJob abortTriggeredJob: true,
        blockBuildUntilComplete: true,
        pollInterval: 240,
        job: REMOTE_JOB_NAME,
        parameters: MapParameters(parameters: paramList),
        remoteJenkinsName: 'temurin-compliance',
        shouldNotFailBuild: true,
        token: 'RemoteTrigger',
        useCrumbCache: true,
        useJobInfoCache: true

    def remoteJobResult = handle.getBuildResult().toString()
    echo "Remote job ${REMOTE_JOB_NAME} (${displayName}) Status: ${remoteJobResult}"

    // Get remote job details and add to build description
    def remoteBuildNumber = handle.getBuildNumber()
    def remoteJobUrl = "https://ci.eclipse.org/temurin-compliance/job/${REMOTE_JOB_NAME}/${remoteBuildNumber}/"
    def remoteBadgeUrl = getResultBadgeUrl(remoteJobResult)

    currentBuild.description += """
        <p>${displayName}:
        <a href="${remoteJobUrl}" target="_blank">
            <img src="${remoteBadgeUrl}" />
        </a>
        </p>
    """

    // Update build result to worst status
    updateBuildResult(remoteJobResult)
}
