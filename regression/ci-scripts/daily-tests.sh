#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

chmod +x regression/ci-scripts/Build-docker-images.sh
./regression/ci-scripts/Build-docker-images.sh
chmod +x regression/ci-scripts/pip-install-daily.sh
./regression/ci-scripts/pip-install-daily.sh
