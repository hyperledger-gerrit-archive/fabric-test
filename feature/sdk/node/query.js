/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

const fs = require('fs');
const util = require('util');
const common = require('./common.js');
const {Gateway, InMemoryWallet, X509WalletMixin} = require('fabric-network');
const Client = require('fabric-client');
let client = new Client();

function query(user, org, cc, peer, network_config_path, options) {

    const chaincode = JSON.parse(cc);
    let opts;

    if (options){
        opts = JSON.parse(options);
    }

    const temptext = '\n\n user : ' + user +
                    '\n\n Org: ' + org +
                    '\n\n chaincode : ' + util.format(chaincode) +
                    '\n\n peerNames : ' + peer +
                    '\n\n network_config_path: ' + network_config_path;

    let network_config_details;
    try {
        network_config_details = JSON.parse(fs.readFileSync(network_config_path));
    } catch(err) {
        console.error(err);
        return {"network-config error": err};
    }

    // Node SDK implements network and native options, disambiguate on the passed opts
    if(opts && opts.transaction && opts.transaction.localeCompare("true") === 0){
        return _executeTransaction(org, chaincode, network_config_details)
    } else {
        return _query(user, peer, org, chaincode, network_config_details)
    }
}

/**
 * 
 */
function _query(user, peer, userOrg, chaincode, network_config_details){
    const username = user.split('@')[0];
    const target = buildTarget(peer, userOrg, network_config_details['network-config']);

    Client.setConfigSetting('request-timeout', 60000);

    // this is a transaction, will just use org's identity to
    // submit the request. intentionally we are using a different org
    // than the one that submitted the "move" transaction, although either org
    // should work properly
    const channel = client.newChannel(chaincode.channelId);

    common.getRegisteredUsers(client, user, user.split('@')[1], network_config_details['networkID'], network_config_details['network-config'][userOrg]['mspid'])
	   .then((tlsInfo) => {
                    client.setTlsClientCertAndKey(tlsInfo.certificate, tlsInfo.key);
                    return Client.newDefaultKeyValueStore({path: common.getKeyStoreForOrg(userOrg)});
            }).then((store) => {
                    client.setStateStore(store);
                    return common.getRegisteredUsers(client, user, user.split('@')[1], network_config_details['networkID'], network_config_details['network-config'][userOrg]['mspid'])
            }).then((admin) => {
                    the_user = admin;
                    tx_id = client.newTransactionID();
                    common.setupPeers(peer, channel, userOrg, client, network_config_details['network-config'], network_config_details['tls']);

                    // send query
                    let request = {
			    targets: [target],
                            txId: tx_id,
                            chaincodeId: chaincode.chaincodeId,
                            fcn: chaincode.fcn,
                            args: chaincode.args
                    };

                    return channel.queryByChaincode(request);
            },
            (err) => {
                    console.error('Failed to get submitter \''+username+'\'');
                    return 'Failed to get submitter \''+username+'\'. Error: ' + err.stack ? err.stack : err;
            }).then((response_payloads) => {
                    if (response_payloads) {
                            console.info(JSON.stringify(["ok", response_payloads.toString() + "\n"]));
                            console.info('query chaincode, response_payloads: ' + util.inspect(response_payloads, {depth: null})    );
                            var jsonResponse = {'response': response_payloads.toString()};
                            console.info(JSON.stringify(["ok", response_payloads.toString() + "\n"]));
                            return JSON.stringify(jsonResponse);
                    } else {
                            console.error('response_payloads is null');
                            return {'error': 'response_payloads is null'};
                    }
            },
            (err) => {
                    console.error(['error', 'Failed to send query due to error:' + err.stack ? err.stack : err]);
                    return {'Error': 'Failed to send query due to error:' + err.stack ? err.stack : err};
            });
};


function buildTarget(peer, org, network_config) {
    var target = null;
    if (typeof peer !== 'undefined') {
        let targets = common.newPeers([peer], org, network_config, client);
        if (targets && targets.length > 0) target = targets[0];
    }
    return target;
}

async function _executeTransaction(org, chaincode, network_config){
        const ccp = network_config['ccp'];
        const orgConfig = ccp.organizations[org];
        const cert = common.readAllFiles(orgConfig.signedCertPEM)[0];
        const key = common.readAllFiles(orgConfig.adminPrivateKeyPEM)[0];
        const inMemoryWallet = new InMemoryWallet();
    
        const gateway = new Gateway();
    
        try {
            await inMemoryWallet.import('admin', X509WalletMixin.createIdentity(orgConfig.mspid, cert, key));
                   
            const opts = {
                wallet: inMemoryWallet,
                identity: 'admin'
            };
    
            await gateway.connect(ccp, opts);
    
            const network = await gateway.getNetwork(chaincode.channelId)
            const contract = await network.getContract(chaincode.chaincodeId);
        
            const args = [chaincode.fcn, ...chaincode.args];
            const result = await contract.submitTransaction(...args);

            gateway.disconnect();

            // Convert buffer item and return object
            return {'response': result.toString('ascii')};
        } catch(err) {
            throw new Error(err);
        };
        
    }

exports.query = query;
require('make-runnable');

// Example test calls
// node query.js query User1@org2.example.com Org2ExampleCom' {"args": ["a"], "fcn":"query", "channelId": "behavesystest", "chaincodeId": "mycc"}' ["peer1.org2.example.com"] /opt/gopath/src/github.com/hyperledger/fabric-test/feature/configs/3f09636eb35811e79e510214683e8447/network-config.json;
// node query.js query User1@org1.example.com Org1ExampleCom '{"channelId": "behavesystest", "args": ["a"], "chaincodeId": "mycc", "name": "mycc", "fcn": "query"}' ['peer0.org1.example.com'] /Users/nkl/go/src/github.com/hyperledger/fabric-test/feature/configs/4fe4f54cc62411e8977eacbc32c08695/network-config.json '{"transaction": "true"}'