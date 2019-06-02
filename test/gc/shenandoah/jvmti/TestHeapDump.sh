#!/bin/sh

#
# Copyright (c) 2017, 2018, Red Hat, Inc. All rights reserved.
#
#  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
#
#  This code is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License version 2 only, as
#  published by the Free Software Foundation.
#
#  This code is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#  version 2 for more details (a copy is included in the LICENSE file that
#  accompanied this code).
#
#  You should have received a copy of the GNU General Public License version
#  2 along with this work; if not, write to the Free Software Foundation,
#  Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
#
#  Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
#  or visit www.oracle.com if you need additional information or have any
#  questions.
#

##
## @test
## @summary test JNI critical arrays support in Shenandoah
## @run shell/timeout=480 TestHeapDump.sh
##

if [ "${TESTSRC}" = "" ]
then
  TESTSRC=${PWD}
  echo "TESTSRC not set.  Using "${TESTSRC}" as default"
fi
echo "TESTSRC=${TESTSRC}"
## Adding common setup Variables for running shell tests.
. ${TESTSRC}/../../../test_env.sh

# set platform-dependent variables
if [ "$VM_OS" = "linux" ]; then
    echo "Testing on linux"
    gcc_cmd=`which gcc`
    if [ "x$gcc_cmd" = "x" ]; then
        echo "WARNING: gcc not found. Cannot execute test." 2>&1
        exit 0;
    fi
else
    echo "Test passed; only valid for linux: $VM_OS"
    exit 0;
fi

THIS_DIR=.

cp ${TESTSRC}${FS}*.java ${THIS_DIR}
${TESTJAVA}${FS}bin${FS}javac TestHeapDump.java

$gcc_cmd -O1 -DLINUX -fPIC -shared \
    -o ${THIS_DIR}${FS}libTestHeapDump.so \
    -I${TESTJAVA}${FS}include \
    -I${TESTJAVA}${FS}include${FS}linux \
    ${TESTSRC}${FS}libTestHeapDump.c

# run the java test in the background
cmd="${TESTJAVA}${FS}bin${FS}java -agentpath:./libTestHeapDump.so -Xmx128m -XX:+UnlockDiagnosticVMOptions -XX:+UnlockExperimentalVMOptions -XX:+UseShenandoahGC -XX:ShenandoahGCHeuristics=aggressive \
    -Djava.library.path=${THIS_DIR}${FS} TestHeapDump"

echo "$cmd"
eval $cmd

if [ $? -ne 0 ]
then
    echo "Test Failed"
    exit 1
fi

if [ "$VM_BITS" = "64" ]; then
  cmd="${TESTJAVA}${FS}bin${FS}java -agentpath:./libTestHeapDump.so -Xmx128m -XX:+UnlockDiagnosticVMOptions -XX:+UnlockExperimentalVMOptions -XX:+UseShenandoahGC -XX:ShenandoahGCHeuristics=aggressive \
      -XX:-UseCompressedOops -Djava.library.path=${THIS_DIR}${FS} TestHeapDump"

  echo "$cmd"
  eval $cmd

  if [ $? -ne 0 ]
  then
      echo "Test Failed"
      exit 1
  fi
else
    echo "Test passed; only valid for 64 bits"
    exit 0;
fi
