##############################################################################
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##############################################################################
ifndef JCK_CUSTOM_TARGET
JCK_CUSTOM_TARGET ?=api/java_math
endif

# Environment variable OSTYPE is set to cygwin if running under cygwin.
# Set our own macro to indicate we're running under cygwin.
ifndef CYGWIN
  OSTYPE?=$(shell echo $$OSTYPE)
  CYGWIN:=0
  ifeq ($(OSTYPE),cygwin)
    CYGWIN:=1
  endif
  ifeq ($(TERM),cygwin)
    CYGWIN:=1
  endif
endif
$(warning CYGWIN is $(CYGWIN))

ifeq ($(CYGWIN),1)
   # If we are running under cygwin, the tests need to run with a Windows perl port (e.g. Strawberry perl) rather
   # than the cygwin perl port. This assumes that version will be in a directory ending /perl/bin directory
   # and the cygwin version will not. Once found, that version of perl is added ahead of cygwin perl in the PATH.
   $(warning Running under cygwin, looking for Windows perl on path)
   PERL:=$(shell which -a perl.exe | grep /perl/bin | sort | uniq)
   ifeq (,$(PERL))
     $(error Unable to find Windows perl e.g. Strawberry perl in a /perl/bin subdirectory on PATH.  Install perl or add to PATH and retry)
   else
     $(warning Found perl in $(PERL))
   endif
   PERL:=$(dir $(PERL))
   export PATH:=$(PERL):$(PATH)
endif


ifndef JCK_VERSION
  ifeq (8, $(JDK_VERSION))
    export JCK_VERSION=jck8c
  else
    export JCK_VERSION=jck$(JDK_VERSION)
  endif
endif

ifndef JCK_ROOT
  export JCK_ROOT=$(TEST_ROOT)/../../../jck_root/JCK$(JDK_VERSION)-unzipped
endif

OTHER_OPTS=
# if JDK_IMPL is openj9 or ibm
ifneq ($(filter openj9 ibm, $(JDK_IMPL)),)
 OTHER_OPTS=-Xtrace:maximal=all{level2}
endif

# If testsuite is not specified, default to RUNTIME
ifeq (,$(findstring testsuite, $(JCK_CUSTOM_TARGET)))
   override JCK_CUSTOM_TARGET := $(JCK_CUSTOM_TARGET) testsuite=RUNTIME
endif

define JCK_CMD_TEMPLATE
$(JAVA_COMMAND) -Djvm.options=$(Q)$(JVM_OPTIONS)$(Q) -Dother.opts=$(OTHER_OPTS) -cp $(TEST_ROOT)/jck/jtrunner/bin JavaTestRunner resultsRoot=$(REPORTDIR) testRoot=$(TEST_ROOT)
endef

VERIFIER_INSTRUCTIONS_TESTS_GROUP1=$(Q)vm/verifier/instructions/aaload;vm/verifier/instructions/aastore;vm/verifier/instructions/anewarray;vm/verifier/instructions/areturn;vm/verifier/instructions/baload;vm/verifier/instructions/bastore;vm/verifier/instructions/bipush;vm/verifier/instructions/caload;vm/verifier/instructions/castore;vm/verifier/instructions/d2f;vm/verifier/instructions/d2i;vm/verifier/instructions/d2l;vm/verifier/instructions/dadd;vm/verifier/instructions/daload;vm/verifier/instructions/dastore;vm/verifier/instructions/dcmp;vm/verifier/instructions/dconst;vm/verifier/instructions/ddiv;vm/verifier/instructions/dmul;vm/verifier/instructions/dneg;vm/verifier/instructions/drem;vm/verifier/instructions/dreturn;vm/verifier/instructions/dsub;vm/verifier/instructions/dup;vm/verifier/instructions/dup2$(Q)
VERIFIER_INSTRUCTIONS_TESTS_GROUP2=$(Q)vm/verifier/instructions/dup2x1;vm/verifier/instructions/dup2x2;vm/verifier/instructions/dupx1;vm/verifier/instructions/dupx2;vm/verifier/instructions/f2d;vm/verifier/instructions/f2i;vm/verifier/instructions/f2l;vm/verifier/instructions/fadd;vm/verifier/instructions/faload;vm/verifier/instructions/fastore;vm/verifier/instructions/fcmp;vm/verifier/instructions/fconst;vm/verifier/instructions/fdiv;vm/verifier/instructions/fmul;vm/verifier/instructions/fneg;vm/verifier/instructions/frem;vm/verifier/instructions/freturn;vm/verifier/instructions/fsub;vm/verifier/instructions/getfield;vm/verifier/instructions/getstatic;vm/verifier/instructions/i2b;vm/verifier/instructions/i2c;vm/verifier/instructions/i2d;vm/verifier/instructions/i2f;vm/verifier/instructions/i2l$(Q)
VERIFIER_INSTRUCTIONS_TESTS_GROUP3=$(Q)vm/verifier/instructions/i2s;vm/verifier/instructions/iadd;vm/verifier/instructions/iaload;vm/verifier/instructions/iand;vm/verifier/instructions/iastore;vm/verifier/instructions/iconst;vm/verifier/instructions/idiv;vm/verifier/instructions/imul;vm/verifier/instructions/ineg;vm/verifier/instructions/ior;vm/verifier/instructions/irem;vm/verifier/instructions/ireturn;vm/verifier/instructions/ishl;vm/verifier/instructions/ishr;vm/verifier/instructions/isub;vm/verifier/instructions/iushr;vm/verifier/instructions/ixor;vm/verifier/instructions/l2d;vm/verifier/instructions/l2f;vm/verifier/instructions/l2i;vm/verifier/instructions/ladd;vm/verifier/instructions/laload;vm/verifier/instructions/land;vm/verifier/instructions/lastore;vm/verifier/instructions/lcmp$(Q)
VERIFIER_INSTRUCTIONS_TESTS_GROUP4=$(Q)vm/verifier/instructions/lconst;vm/verifier/instructions/ldc;vm/verifier/instructions/ldc_w;vm/verifier/instructions/ldc2_w;vm/verifier/instructions/ldiv;vm/verifier/instructions/lmul;vm/verifier/instructions/lneg;vm/verifier/instructions/lor;vm/verifier/instructions/lrem;vm/verifier/instructions/lreturn;vm/verifier/instructions/lshl;vm/verifier/instructions/lshr;vm/verifier/instructions/lsub;vm/verifier/instructions/lushr;vm/verifier/instructions/lxor;vm/verifier/instructions/newarray;vm/verifier/instructions/pop;vm/verifier/instructions/pop2;vm/verifier/instructions/putfield;vm/verifier/instructions/putstatic;vm/verifier/instructions/saload;vm/verifier/instructions/sastore;vm/verifier/instructions/sipush;vm/verifier/instructions/swap$(Q)