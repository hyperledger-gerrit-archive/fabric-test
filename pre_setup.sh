#!/bin/bash -e
set -o pipefail

# Install nvm to install multi node versions;
#neet to match the pathspec below the same as in ./fabric/devenv/install_nvm.sh.
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.4/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# Install nodejs version 8.9.4
nvm install $NODE_VER || true

# use nodejs 8.9.4 version
nvm use --delete-prefix v$NODE_VER 

echo "npm version ======>"
npm -v
echo "node version =======>"
node -v
