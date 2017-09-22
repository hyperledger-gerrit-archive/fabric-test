/**
 * Copyright IBM Corp All Rights Reserved
 *
 * SPDX-License-Identifier: Apache-2.0
 */
'use strict';
const path = require('path');
const fs = require('fs');
const util = require('util');
const hfc = require('fabric-client');
const Peer = require('fabric-client/lib/Peer.js');
const common = require('./sdk/node/common.js');
// const common = require('./common.js');
const EventHub = require('fabric-client/lib/EventHub.js');
let client = new hfc();

var invoke = function(username, org, chaincode, peerNames, orderer, network_config_path) {
	var temptext = '\n\n Username : '+username +
						 '\n\n Org: '+org+
						 '\n\n chaincode : '+util.format(chaincode)+
						 '\n\n peerNames : '+peerNames+
						 '\n\n orderer: '+orderer+
						 '\n\n network_config_path: '+network_config_path;
	fs.writeFile('behavelog.txt', temptext, (err) => {
    // throws an error, you could also catch it here
    if (err) throw err;

});
var peerNames = [peerNames];
	// Read Network JSON PATH from behave
	let network_config;
	try {
		network_config = JSON.parse(fs.readFileSync(network_config_path));
	} catch(err) {
		console.error(err);
		return err;
	}

	fs.writeFile('channel.txt', chaincode.channelId, (err) => {
		// throws an error, you could also catch it here
		if (err) throw err;
	});
	let channel = client.newChannel(chaincode.channelId);
	channel.addOrderer(common.newOrderer(client, network_config['network-config'], orderer));

	common.setupPeers(peerNames, channel, org, client, network_config['network-config']);
	let targets = (peerNames) ? common.newPeers(peerNames, org, network_config['network-config'], client) : undefined;
	let tx_id = null;
	return common.getRegisteredUsers(client, username, username.split('@')[1], network_config['networkID']).then((user) => {
		tx_id = client.newTransactionID();
		// send proposal to endorser
		let request = {
			chaincodeId: chaincode.chaincodeId,
			fcn: chaincode.fcn,
			args: chaincode.args,
			chainId: chaincode.channelId,
			txId: tx_id
		};

		if (targets) {
			request.targets = targets;
		}

		return channel.sendTransactionProposal(request);
	}, (err) => {
		console.error('Failed to enroll user \'' + username + '\'. ' + err);
		throw new Error('Failed to enroll user \'' + username + '\'. ' + err);
	}).then((results) => {
		let proposalResponses = results[0];
		let proposal = results[1];
		let all_good = true;
		for (var i in proposalResponses) {
			let one_good = false;
			if (proposalResponses && proposalResponses[i].response &&
				proposalResponses[i].response.status === 200) {
				one_good = true;
			} else {
				console.error('transaction proposal was bad');
			}
			all_good = all_good & one_good;
		}
		if (all_good) {
			var request = {
				proposalResponses: proposalResponses,
				proposal: proposal
			};
			// set the transaction listener and set a timeout of 30sec
			// if the transaction did not get committed within the timeout period,
			// fail the test
			let transactionID = tx_id.getTransactionID();
			let eventPromises = [];

			if (!peerNames) {
				peerNames = channel.getPeers().map(function(peer) {
					return peer.getName();
				});
			}

			let eventhubs = common.newEventHubs(peerNames, org, network_config['network-config'], client);
			for (let key in eventhubs) {
				let eh = eventhubs[key];
				eh.connect();

				let txPromise = new Promise((resolve, reject) => {
					let handle = setTimeout(() => {
						eh.disconnect();
						reject();
					}, 30000);

					eh.registerTxEvent(transactionID, (tx, code) => {
						clearTimeout(handle);
						eh.unregisterTxEvent(transactionID);
						eh.disconnect();

						if (code !== 'VALID') {
							reject();
						} else {
							resolve();
						}
					});
				});
				eventPromises.push(txPromise);
			};
			let sendPromise = channel.sendTransaction(request);
			return Promise.all([sendPromise].concat(eventPromises)).then((results) => {
				return results[0]; // the first returned value is from the 'sendPromise' which is from the 'sendTransaction()' call
			}).catch((err) => {
				console.error(
					'Failed to send transaction and get notifications within the timeout period.'
				);
				return 'Failed to send transaction and get notifications within the timeout period.';
			});
		} else {
			console.error(
				'Failed to send Proposal or receive valid response. Response null or status is not 200. exiting...'
			);
			return 'Failed to send Proposal or receive valid response. Response null or status is not 200. exiting...';
		}
	}, (err) => {
		console.error('Failed to send proposal due to error: ' + err.stack ? err.stack :
			err);
		return 'Failed to send proposal due to error: ' + err.stack ? err.stack :
			err;
	}).then((response) => {
		if (response.status === 'SUCCESS') {
			var jsonResponse = {'tx_id' : tx_id.getTransactionID().toString()};
			console.info(JSON.stringify(["ok", jsonResponse]));
			return JSON.stringify(jsonResponse);
		} else {
			console.error('Failed to order the transaction. Error code: ' + response.status);
			return 'Failed to order the transaction. Error code: ' + response.status;
		}
	}, (err) => {
		console.error('Failed to send transaction due to error: ' + err.stack ? err
			.stack : err);
		return 'Failed to send transaction due to error: ' + err.stack ? err.stack :
			err;
	});
};

//invoke('User1@org1.example.com', 'Org1ExampleCom', {'channelId': 'behavesystest', 'args': ['a', 'b', '10'], 'chaincodeId': 'mycc', 'name': 'mycc', 'fcn': 'invoke'}, "peer0.org1.example.com", "orderer0.example.com", "/opt/gopath/src/github.com/hyperledger/fabric-test/feature/configs/3ea89a44b03211e79e510214683e8447/network-config.json");
exports.invoke = invoke;
