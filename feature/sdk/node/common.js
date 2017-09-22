'use strict';
const log4js = require('log4js');
var logger = log4js.getLogger('SDK_INT');
logger.setLevel('DEBUG');

var path = require('path');
var util = require('util');
var fs = require('fs-extra');

function setupPeers(peers, channel, org, client) {
  let tls = network_contents.tls;
  let nodes = network_file_contents.nodes;
  for (let key in nodes) {
    if (peers.indexOf(key)) {
      let data = fs.readFileSync(path.join(__dirname, nodes[key].tlsCert));
      let peer = client.newPeer(
        nodes[key].url, {
          pem: Buffer.from(data).toString(),
          'ssl-target-name-override': key
        }
      );
      peer.setName(key);
      channel.addPeer(peer);
    }
  }
}

function newRemotes(names, forPeers, userOrg, network_config) {
	let client = getClientForOrg(userOrg);

	let targets = [];
	// find the peer that match the names
	for (let idx in names) {
		let peerName = names[idx];
    let peerNode = network_config.nodes[peerName];
		if (peerNode) {
			// found a peer matching the name
      // let tls = network_config.tls && network_config.tls === 'tls';
      let grpcOpts = {};
      if (network_config.tls && network_config.tls === 'tls'){
        let data = fs.readFileSync(path.join(__dirname, peerNode.tlsCert));
        grpcOpts[pem] = Buffer.from(data).toString();
        grpcOpts[ssl-target-name-override] = peerName;
      }
			if (forPeers) {
				targets.push(client.newPeer(peerNode.url, grpcOpts));
			} else {
				let eh = client.newEventHub();
				eh.setPeerAddr(peerNode.eventsUrl, grpcOpts);
				targets.push(eh);
			}
		}
	}

	if (targets.length === 0) {
		logger.error(util.format('Failed to find peers matching the names %s', names));
	}

	return targets;
}
var newPeers = function(names, org, network_config) {
	return newRemotes(names, true, org, network_config);
};

var newEventHubs = function(names, org, network_config) {
	return newRemotes(names, false, org, network_config);
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
	return ORGS[org].name;
}

function getKeyStoreForOrg(org) {
	return hfc.getConfigSetting('keyValueStore') + '_' + org;
}

function newRemotes(names, forPeers, userOrg, network_config) {
	let client = getClientForOrg(userOrg);

	let targets = [];
	// find the peer that match the names
	for (let idx in names) {
		let peerName = names[idx];
    let nodes = network_config.nodes;
		if (nodes[peerName] == peerName) {
			// found a peer matching the name
			let data = fs.readFileSync(path.join(__dirname, nodes[peerName].tlsCerts));
			let grpcOpts = {
				pem: Buffer.from(data).toString(),
				'ssl-target-name-override': peerName
			};

			if (forPeers) {
				targets.push(client.newPeer(nodes[peerName].url, grpcOpts));
			} else {
				let eh = client.newEventHub();
				eh.setPeerAddr(nodes[peerName].eventsUrl, grpcOpts);
				targets.push(eh);
			}
		}
	}

	if (targets.length === 0) {
		logger.error(util.format('Failed to find peers matching the names %s', names));
	}

	return targets;
}
var getRegisteredUsers = function(username, userOrg, isJson) {
  //a: BDD: Get the acurate paths
	var keyPath = path.join(__dirname, util.format('../configs/%s/peerOrganizations/%s.example.com/users/%s@%s.example.com/msp/keystore/', networkID, userOrg, username, userOrg));
	var keyPEM = Buffer.from(readAllFiles(keyPath)[0]).toString();
	var certPath = path.join(__dirname, util.format('../configs/%s/peerOrganizations/%s.example.com/users/%s@%s.example.com/msp/signcerts/', networkID, userOrg, username, userOrg));
	var certPEM = readAllFiles(certPath)[0].toString();

	var client = getClientForOrg(userOrg);
	var cryptoSuite = hfc.newCryptoSuite();
  //TODO: We wanted to clear this dir right after the test ?
  cryptoSuite.setCryptoKeyStore(hfc.newCryptoKeyStore({path: '/tmp/fabric-client-kvs_'+userOrg}));
	client.setCryptoSuite(cryptoSuite);

	return hfc.newDefaultKeyValueStore({
		path: getKeyStoreForOrg(getOrgName(userOrg))
	}).then((store) => {
		client.setStateStore(store);

		return client.createUser({
			username: username,
			mspid: getMspID(userOrg),
			cryptoContent: {
				privateKeyPEM: keyPEM,
				signedCertPEM: certPEM
			}
		});
	});
}
