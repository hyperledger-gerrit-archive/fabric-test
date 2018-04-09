## Dockerfile for building the PTE image

# Base Nodejs image to use
FROM library/node:8.11

ENV GOPATH /root/go
RUN apt update && apt install -y git

COPY . $GOPATH/src/github.com/hyperledger/fabric-test

RUN cd $GOPATH/src/github.com/hyperledger/fabric-test \
    && git submodule update --init --recursive && git submodule foreach git pull origin master \
    && cd fabric-sdk-node && npm install && npm install -g gulp \
    && gulp ca && cp -r ../tools/PTE test/

WORKDIR $GOPATH/src/github.com/hyperledger/fabric-test/fabric-sdk-node/test/PTE
