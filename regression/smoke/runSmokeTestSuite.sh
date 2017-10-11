#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "========== Behave feature and system tests..."
python --version
cd ../../feature
behave --junit --junit-directory . -t smoke
python --version
cd -
