#!/bin/bash -e
set -o pipefail

# Install nvm to install multi node versions
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# Install nodejs version 8.9.0
nvm install 8.9.0 || true

# use nodejs 8.9.0 version
nvm use --delete-prefix v8.9.0

echo "npm version ======>"
npm -v
echo "node version =======>"
node -v
