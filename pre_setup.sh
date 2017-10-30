#!/bin/bash -e
set -o pipefail

# Install nvm to install multi node versions
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# Install nodejs version 8.4.0
nvm install 8.4.0 || true

# use nodejs 8.4.0 version
nvm use 8.4.0

echo "npm version ======>"
npm -v
echo "node version =======>"
node -v

# intialize govendor for chaincode tests
cd $GOPATH/src/github.com/hyperledger/fabric/examples/chaincode/go/enccc_example || exit
go get -u github.com/kardianos/govendor && govendor init && govendor add +external
