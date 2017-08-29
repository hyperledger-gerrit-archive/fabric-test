Welcome to fabric-test
-------
You are in the right place if you are interested in testing the Hyperledger Fabric and related repositories.

## Getting Started
Here are some recommended setup steps.

#### Clone the repositories.

```
  cd $GOPATH/github.com/hyperledger
  clone the fabric-ca
  clone the fabric
  clone the cello
  clone the fabric-test
```

#### Update git submodules

```
  cd fabric-test
  git submodule update --init --recursive
```

#### Get and build the latest code

```
  cd ../fabric-ca
  make docker

  cd ../fabric
  make docker configtxgen cryptogen

  # cello instructions coming soon  #WIP
```

## Run some tests

#### Run test suites or individual tests in behave

```
  cd $GOPATH/hyperledger/fabric-test/feature
  behave -t smoke
  behave -t daily
  behave -n 4770
```

#### Start a network using networkLauncher tool, save logs, and clean up afterwards

```
  cd $GOPATH/hyperledger/fabric-test/tools/NL
  ./networkLauncher.sh -h
  ./networkLauncher.sh -o 3 -x 6 -r 6 -p 2 -k 3 -z 3 -n 3 -t kafka -f test -w localhost -S enabled
  ./savelogs.sh   ### script to save all logs ### WIP ###
  ./cleanup.sh    ### script to tear down network and remove artifacts ### WIP ###
```

