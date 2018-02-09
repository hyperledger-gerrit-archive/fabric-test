# End-to-end upgrade scenario from 1.0.x to 1.1
- Launching the fabric network with v1.0.x, perform create channel, join peers to channel, install and instantiate the chaincode, and invokes and queries
- Upgrading the fabric orderers, peers from v1.0.x to v1.1
- Enabling the capabilities, perform create channel, join peers to channel, install and instantiate the chaincode, and invokes and queries

# Running the scenario
- Clone the repository fabric-test (if not already cloned). Refer [Fabric-test README] (https://github.com/hyperledger/fabric-test/blob/master/README.md)
- Change the directory to fabric-test/feature-upgrade/cli
- Use the `network_setup.sh` script to launch the network and perform the end-to-end scenario
  ```Usage: ./network_setup.sh <up|down|restart|upgrade> <\$channel-prefix> <\$cli_timeout> <couchdb>```
- ``` ./network_setup.sh up                   # launches the network using latest images and uses  default values for channel-prefix```
- ``` ./network_setup.sh up mychannel 10      # launches the network using latest images, channel prefix name is mychannel which creates mychannel1 mychannel2, cli_timeout is 10 ```
- ``` ./network_setup.sh upgrade              # launches the network using 1.0.3 images, performs create channel mychannel1, join peers to mychannel1, install, instantiate, invoke and query, upgrade network to use latest images, perform invoke and query on existing mychannel1, then create mychannel2 channel, join peers to mychannel2, install, instantiate, invoke and query while enabling the capabilities on /Channel, /Channel/Orderer, /Channel/Application ```
- ``` ./network_setup.sh down                 # removes the network and artifacts
- During the launch or upgrade, the ledger data will be backed to orderer/ directory from orderer and peers/peer0, peers/peer1, peers/peer2, peers/peer3 directories from respective peers. When launching a new network, the data in the mentioned directories should be cleared ``` sudo rm -rf orderer/* peers/*/*
