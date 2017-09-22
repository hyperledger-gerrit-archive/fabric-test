/**
 * Copyright 2017 IBM All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
var path = require('path');
var fs = require('fs');
var util = require('util');
var hfc = require('fabric-client');
var Peer = require('fabric-client/lib/Peer.js');
var EventHub = require('fabric-client/lib/EventHub.js');
// const common = require('./common.js');
const common = require('./sdk/node/common.js');

let client = new hfc();

var query = function(user, userOrg, chaincode, peer, network_config_path) {
let username = user.split('@')[0];
let network_config
try {
	network_config_path = JSON.parse(fs.readFileSync(network_config_path));
	network_config = network_config_path['network-config'];
} catch(err) {
	console.error(err);
	return err;
}

let channel = client.newChannel(chaincode.channelId);

	var target = buildTarget(peer, userOrg, network_config);
	return common.getRegisteredUsers(client, user, user.split('@')[1], network_config_path['networkID']).then((user) => {
		tx_id = client.newTransactionID();
		// send query
		var request = {
			targets: [target],
			chaincodeId: chaincode.chaincodeId,
			txId: tx_id,
			fcn: chaincode.fcn,
			args: chaincode.args
		};
		return channel.queryByChaincode(request);
	}, (err) => {
		console.error('Failed to get submitter \''+username+'\'');
		return 'Failed to get submitter \''+username+'\'. Error: ' + err.stack ? err.stack :
			err;
	}).then((response_payloads) => {
		if (response_payloads) {
			for (let i = 0; i < response_payloads.length; i++) {
				// console.log(chaincode.args[0]+' now has ' + response_payloads[i].toString('utf8') +
				// 	' after the invoke');
				// return chaincode.args[0]+' now has ' + response_payloads[i].toString('utf8') +
				// 	' after the invoke';
				return {'response': response_payloads[i].toString('utf8')};
			}
		} else {
			console.error('response_payloads is null');
			return {'error': 'response_payloads is null'};
		}
	}, (err) => {
		console.error('Failed to send query due to error: ' + err.stack ? err.stack :
			err);
		return 'Failed to send query due to error: ' + err.stack ? err.stack : err;
	}).catch((err) => {
		console.error('Failed to end to end test with error:' + err.stack ? err.stack :
			err);
		return 'Failed to end to end test with error:' + err.stack ? err.stack :
			err;
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

// query('User1@org1.example.com', 'Org1ExampleCom', {"args": ["a"], "fcn":"query", "channelId": "behavesystest", "chaincodeId": "mycc"}, ["peer0.org1.example.com"], "/Users/ratnakar/workspace/go/src/github.com/hyperledger/fabric-test/feature/configs/b170a4aeaf4211e794b580e65025f612/network-config.json");

exports.query = query;
