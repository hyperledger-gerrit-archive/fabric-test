#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

CurrentDirectory=$(cd `dirname $0` && pwd)
FabricTestDir=$CurrentDirectory/../..
INTEROPDIR="$FabricTestDir/regression/interop"
cd $INTEROPDIR

echo "======== Interoperability tests... ========"
cd ../../feature
behave --junit --junit-directory ../regression/interop/. --tags=-skip --tags=interop -k -D logs=y
cd -

