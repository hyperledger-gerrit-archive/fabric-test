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
//    fs.writeFile('behave_invoke.log', temptext, (err) => {
//        // throws an error, you could also catch it here
//        if (err) throw err;
//    });
    var peerNames = [peerNames];
    // Read Network JSON PATH from behave
    let network_config;
    try {
        network_config = JSON.parse(fs.readFileSync(network_config_path));
    } catch(err) {
        console.error(err);
        return err;
    }

//     fs.writeFile('channel.txt', chaincode.channelId, (err) => {
//         // throws an error, you could also catch it here
//         if (err) throw err;
//     });
    let channel = client.newChannel(chaincode.channelId);
    channel.addOrderer(common.newOrderer(client, network_config['network-config'], orderer, network_config['tls']));

    common.setupPeers(peerNames, channel, org, client, network_config['network-config'], network_config['tls']);
    let targets = (peerNames) ? common.newPeers(peerNames, org, network_config['network-config'], client) : undefined;
//     fs.writeFile('targets.txt', targets, (err) => {
//         // throws an error, you could also catch it here
//         if (err) throw err;
//     });

    let tx_id = null;
    console.info(JSON.stringify(["ok", "Getting registered user"]));
    return common.getRegisteredUsers(client, username, username.split('@')[1], network_config['networkID'], network_config['network-config'][org]['mspid']).then((user) => {
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

        console.info(JSON.stringify(["ok", "request is set"]));
        return channel.sendTransactionProposal(request, 12000);
    }, (err) => {
        console.error('Failed to enroll user \'' + username + '\'. ' + err);
    throw new Error('Failed to enroll user \'' + username + '\'. ' + err);
    }).then((results) => {
        console.info(JSON.stringify(["ok", "proposal sent"]));
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
            console.info(JSON.stringify(["ok", "sending Transaction"]));
            return Promise.all([sendPromise].concat(eventPromises)).then((results) => {
                return results[0]; // the first returned value is from the 'sendPromise' which is from the 'sendTransaction()' call
            }).catch((err) => {
                console.error(JSON.stringify(
                    ["error", 'Failed to send transaction and get notifications within the timeout period.']
		    )
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
            // var jsonResponse = {'tx_id' : tx_id.getTransactionID().toString()};
            // console.info(JSON.stringify(["ok", jsonResponse]));
            // return JSON.stringify(["ok",jsonResponse]);
            // var jsonResponse = ["ok", {'tx_id' : tx_id.getTransactionID().toString()}];
            // console.info(JSON.stringify(jsonResponse));
            var jsonResponse = ["ok", tx_id.getTransactionID().toString()];
            console.info(JSON.stringify(jsonResponse));
            return JSON.stringify(jsonResponse);
        } else {
            console.error(JSON.stringify(["ok", 'Failed to order the transaction. Error code: ' + response.status]));
            return 'Failed to order the transaction. Error code: ' + response.status;
        }
    }, (err) => {
        console.error('Failed to send transaction due to error: ' + err.stack ? err
            .stack : err);
        return 'Failed to send transaction due to error: ' + err.stack ? err.stack :
            err;
    });
};

// invoke('User1@org1.example.com', 'Org1ExampleCom', {'channelId': 'behavesystest', 'args': ['m', '26687534657789876543245678976543567890876543678908765435678908765435678908765432567897654356789765435678654324567896543245678976543245678976543245678765435678976543678976543567876543567865435678654325678654356789765436787654325678976543567865435678765435678976543678976547897654678976547897654678654678976546787654678976547876543678976543567897654356789765435678654356787654356789765456787654324567898765432345678987654323456789876543234567898765432345678765432345678765434567876543567876543432343456786567887686543234565434564345676543456765456765456787654567876543567876543567876543456787654345678765434567876543234567654345678976543234567876543234567876543234567898765432345678987654323456787654345678987654345678909876545678987654567876545678765678765456543432421321121232343245678798090989098909809890989878987654567876543456789765456789876543456789765434567876545678765435678987654567898765434567876543234567876543456787654e43567876543e4567890987890-098765432345654edddfdfdafde4567898767890987654567898765678765678765456765434567865434567890987654345678987654345678976543456787654345678765432345678765434567876543245678987654323453243245654567898798789098765432323234567890o87656787909098765432345678909876543234567898765432345678987654356789876543432132123456765678976789876789876543234567876543234567898765432345678987654345678987654323456787654323456789876543234567876543234567898765432345678987654324567876543234567898765432345678765432345678976543456789876545678987654567898765456765676578765467876567876567897654567654345643213456787654567898909876543234321232345678987654567898787654356789909090909099098767878909890987898765434543455678789765432343212321232123212345678765432345678765432456789876543456789876543456789765555555555555555654444444444444444444786543678654325678976543245678907654325678907654325678976543245678907654324567898765432567890876543245678976543245678976543245678987654324567890876543245678908765432456789087654356789087654324567890876543256789765432567890876543245678976543245678965432456789765432456786543214567896543214567897654325678976543256789654356789765432567896543567897654356789765435678976543567897654356786543256786543256789654356789654325678654356786543256786543245678543256785432456786543256786543567865432456786543214567854325678965432145678654325678976543213456789654321456789765432145678965432567897654324567897654324567897654324567876543256787654325678654325678654325678654325678b864210'], 'chaincodeId': 'mycc', 'name': 'mycc', 'fcn': 'put'}, "peer0.org1.example.com", "orderer0.example.com", "/opt/gopath/src/github.com/hyperledger/fabric-test/feature/configs/864b22f2b41711e79e510214683e8447/network-config.json");
//invoke('User1@org1.example.com', 'Org1ExampleCom', {'channelId': 'behavesystest', 'args': ['a', 'b', '10'], 'chaincodeId': 'mycc', 'name': 'mycc', 'fcn': 'invoke'}, "peer0.org1.example.com", "orderer0.example.com", "/opt/gopath/src/github.com/hyperledger/fabric-test/feature/configs/3ea89a44b03211e79e510214683e8447/network-config.json");
exports.invoke = invoke;
