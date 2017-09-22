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
'use strict';
const path = require('path');
const fs = require('fs');
const util = require('util');
const hfc = require('fabric-client');
const Peer = require('fabric-client/lib/Peer.js');
// const helper = require('./helper.js');
// const common = require('./common.js');
const common = require('./sdk/node/common.js');
//const logger = common.logger;//getLogger('invoke-chaincode');
const EventHub = require('fabric-client/lib/EventHub.js');
let client = new hfc();
// const configuration = require('/Users/ratnakar/workspace/go/src/github.com/hyperledger/fabric-test/feature/configs/58bf10d4ad3511e7a2f680e65025f612/network-config.json');

// var invokeChaincode = function(user, org, chaincode, peerNames, orderer, network_config_path) {
var invoke = function(username, org, chaincode, peerNames, orderer, network_config_path) {
	console.log(util.format('\n============ invoke transaction on organization %s ============\n', org));

	// Read Network JSON PATH from behave
	let network_config
	network_config_path = path.join(__dirname, '../../', network_config_path);
	try {
		network_config = JSON.parse(fs.readFileSync(network_config_path));
	} catch(err) {
		console.error(err);
		return err;
	}

	let channel = client.newChannel(chaincode.channelId);
	channel.addOrderer(common.newOrderer(client, network_config, orderer));

	common.setupPeers(peerNames, channel, org, client, network_config);
	let targets = (peerNames) ? common.newPeers(peerNames, org, network_config, client) : undefined;
	let tx_id = null;

	return common.getRegisteredUsers(client, username, org).then((user) => {
		// client.setUserContext(user);
		tx_id = client.newTransactionID();
		console.log(util.format('Sending transaction "%j"', tx_id));
		// send proposal to endorser
		let request = {
			chaincodeId: chaincode.chaincodeId,
			fcn: 'invoke',
			args: chaincode.args,
			chainId: chaincode.channelId, //'behavesystest'
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
				console.info('transaction proposal was good');
			} else {
				console.error('transaction proposal was bad');
			}
			all_good = all_good & one_good;
		}
		if (all_good) {
			console.log(util.format(
				'Successfully sent Proposal and received ProposalResponse: Status - %s, message - "%s", metadata - "%s", endorsement signature: %s',
				proposalResponses[0].response.status, proposalResponses[0].response.message,
				proposalResponses[0].response.payload, proposalResponses[0].endorsement
				.signature));
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

			let eventhubs = common.newEventHubs(peerNames, org, network_config, client);
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
							console.error(
								'The balance transfer transaction was invalid, code = ' + code);
							reject();
						} else {
							console.info(
								'The balance transfer transaction has been committed on peer ' +
								eh._ep._endpoint.addr);
							resolve();
						}
					});
				});
				eventPromises.push(txPromise);
			};
			let sendPromise = channel.sendTransaction(request);
			return Promise.all([sendPromise].concat(eventPromises)).then((results) => {
				console.log(' event promise all complete and testing complete');
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
			console.info('Successfully sent transaction to the orderer.');
			return tx_id.getTransactionID();
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

// function invoke(user, org, chaincode, peers, orderer, network_config_path) {
// 	// console.log(network_config_path);
// 	invokeChaincode (user, org, chaincode, peers, orderer, network_config_path);
// }

// invokeChaincode('User1', 'Org1ExampleCom', {'channelId':'behavesystest', 'args':['a','b','10'], 'chaincodeId': 'mycc'}, ['peer0.org1.example.com'],'0', configuration['network-config']);

exports.invoke = invoke;
