#!/bin/bash -e
#
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 IBM Corporation, The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License 2.0
# which accompanies this distribution, and is available at
# https://www.apache.org/licenses/LICENSE-2.0
##############################################################################
set -o pipefail

# Install nvm to install multi node versions;

#neet to match the pathspec below the same as in ./fabric/devenv/install_nvm.sh.
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.4/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

# Install nodejs version 8.11.3
nvm install 8.11.3

# use nodejs 8.11.3 version
nvm use --delete-prefix v8.11.3

echo "npm version ======>"
npm -v
echo "node version =======>"
node -v

###################
# Install govender
###################
echo "Install govendor"
go get -u github.com/kardianos/govendor
