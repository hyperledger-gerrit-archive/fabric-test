#!/bin/bash -e
set -o pipefail

# Install nvm to install multi node versions;
#neet to match the pathspec below the same as in ./fabric/devenv/install_nvm.sh.
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.4/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# Install nodejs version 8.11.3
nvm install 8.11.3 || true

# use nodejs 8.11.3 version
nvm use --delete-prefix v8.11.3

echo "npm version ======>"
npm -v
echo "node version =======>"
node -v

### No longer needed because we are disabling the chaincodes.feature tests that require "I vendor" steps
### (i.e. the shipAPI tests). They are being removed and fabric code is redesigned in master branch anyways.
###  ###################
###  # Install govender
###  ###################
###  echo "Install govendor"
###  go get -u github.com/kardianos/govendor
