/**
 * Copyright IBM Corp All Rights Reserved
 *
 * SPDX-License-Identifier: Apache-2.0
 */
'use strict';
const log4js = require('log4js');
var logger = log4js.getLogger('SDK_INT');

var path = require('path');
var util = require('util');
var fs = require('fs-extra');
const hfc = require('fabric-client');
function setupPeers(peers, channel, org, client, network_config) {
  let tls = network_config.tls;
  let nodes = network_config[org]['peers'];
  for (let key in nodes) {

    if (peers.indexOf(key) >= 0) {
      let peer;
      if (tls === 'true'){
        let data = fs.readFileSync(nodes[key].tls_cacerts);
        peer = client.newPeer(
          nodes[key].requests, {
            pem: Buffer.from(data).toString(),
            'ssl-target-name-override': key
          }
        );
      } else {
        peer = client.newPeer(nodes[key].requests);
      }

      peer.setName(key);
      channel.addPeer(peer);
    }
  }
}

var newPeers = function(names, org, network_config, client) {
	return newRemotes(names, true, org, network_config, client);
};

var newEventHubs = function(names, org, network_config, client) {
	return newRemotes(names, false, org, network_config, client);
};

function readAllFiles(dir) {
	var files = fs.readdirSync(dir);
	var certs = [];
	files.forEach((file_name) => {
		let file_path = path.join(dir,file_name);
		let data = fs.readFileSync(file_path);
		certs.push(data);
	});
	return certs;
}

function getOrgName(org) {
	return 'Org1ExampleCom'; //TODO: check with Latitia
}

function getKeyStoreForOrg(org) {
	return hfc.getConfigSetting('keyValueStore') + '_' + org;
}

function newRemotes(names, forPeers, userOrg, network_config, client) {
	let targets = [];
	// find the peer that match the names
	for (let idx in names) {
		let peerName = names[idx];
    let nodes = network_config[userOrg]['peers'];
		if (nodes[peerName]) {
			// found a peer matching the name
      let data = fs.readFileSync(nodes[peerName].tls_cacerts);
			let grpcOpts = {
				pem: Buffer.from(data).toString(),
				'ssl-target-name-override': ''+peerName
			};
			if (forPeers) {
				targets.push(client.newPeer(nodes[peerName].requests, grpcOpts));
			} else {
				let eh = client.newEventHub();
				eh.setPeerAddr(nodes[peerName].events, grpcOpts);
				targets.push(eh);
			}
		}
	}

	if (targets.length === 0) {
		logger.error(util.format('Failed to find peers matching the names %s', names));
	}
	return targets;
}

function newOrderer(client, network_config, orderer) {
	// let tls = network_config.tls;
	let tls = 'true';//TODO: this is missing ? check with Latitia
	let url = network_config.orderer.url;
	if (tls && tls === 'true'){
		let data = fs.readFileSync(network_config.orderer.tls_cacerts);
		let pem = Buffer.from(data).toString();
		return client.newOrderer(url, {
			'pem': pem,
			'ssl-target-name-override': network_config.orderer['server-hostname']
		});
	} else {
		return client.newOrderer(url);
	}
}


var getRegisteredUsers = function(client, username, org, networkID) {
  // let userOrg = username.split('@')[1];
  // var keyPath = path.join(__dirname, '../..', util.format('./configs/%s/peerOrganizations/%s.example.com/users/%s@%s.example.com/msp/keystore/', networkID, userOrg, username, userOrg));
	var keyPath = util.format('./configs/%s/peerOrganizations/%s/users/%s/msp/keystore/', networkID, org, username);
	var keyPEM = Buffer.from(readAllFiles(keyPath)[0]).toString();
  // var certPath = path.join(__dirname, '../..', util.format('./configs/%s/peerOrganizations/%s.example.com/users/%s@%s.example.com/msp/signcerts/', networkID, userOrg, username, userOrg));
	var certPath = util.format('./configs/%s/peerOrganizations/%s/users/%s/msp/signcerts/', networkID, org, username);
	var certPEM = readAllFiles(certPath)[0].toString();

	var cryptoSuite = hfc.newCryptoSuite();
  //TODO: We wanted to clear this dir right after the test ?
  cryptoSuite.setCryptoKeyStore(hfc.newCryptoKeyStore({path: '/tmp/fabric-client-kvs_'+org.split('.')[0]}));
	client.setCryptoSuite(cryptoSuite);

	return hfc.newDefaultKeyValueStore({
		path: getKeyStoreForOrg(getOrgName(org))
	}).then((store) => {
		client.setStateStore(store);

		return client.createUser({
			username: username.split('@')[0],
			mspid: getMspID(org),
			cryptoContent: {
				privateKeyPEM: keyPEM,
				signedCertPEM: certPEM
			}
		});
	});
}
var getMspID = function(org) {
	return 'org1.example.com'; //TODO: Get the right values
};
exports.newPeers = newPeers;
exports.newEventHubs = newEventHubs;
exports.setupPeers = setupPeers;
exports.newRemotes = newRemotes;
exports.newOrderer = newOrderer;
exports.getRegisteredUsers = getRegisteredUsers;
