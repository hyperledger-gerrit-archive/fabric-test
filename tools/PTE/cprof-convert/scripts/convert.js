/**
 * Copyright 2018 IBM All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const util = require('util');
const fs = require('fs');
const path = require('path');

var cpFilenames = fs.readdirSync(path.join(__dirname, '../config/')).filter(filename => filename.startsWith("creds"));
var cpJsons = [];
cpFilenames.forEach(filename => {
  cpJsons.push(require('../config/' + filename));
});

var pteJson = {
  'test-network': {
    'orderer': {}
  }
};

// Get all orderers (orderer list should be same for each connection profile)
var orderers = cpJsons[0].orderers;

var orgs = {}; var peers = {}; var cas = {};
cpJsons.forEach(cpJson => {
  orgs = {...orgs, ...cpJson.organizations}; // Consolidate all orgs into single object
  peers = {...peers, ...cpJson.peers}; // Consolidate all peers into single object
  cas = {...cas, ...cpJson.certificateAuthorities} // Consolidate all CAs into single object
});

var ordKeys = Object.keys(orderers);
var orgKeys = Object.keys(orgs);
var peerKeys = Object.keys(peers);

// TODO: Assuming that tlsCACerts.pem values are identical between orderers (the existence of multiple
//       orderers is for the sake of HA, so there's no reason that the certs should differ, I think).
pteJson['test-network']['tls_cert'] = orderers[ordKeys[0]].tlsCACerts.pem; 

ordKeys.forEach(ordKey => {
  var ord = {
    name: 'OrdererOrg',
    mspid: 'OrdererOrg',
    mspPath: '',
    adminPath: '',
    comName: '',
    url: orderers[ordKey].url,
    'server-hostname': null,
    tls_cacerts: pteJson['test-network']['tls_cert'] // TODO: verify this
  };
  pteJson['test-network']['orderer'][ordKey] = ord;
})


orgKeys.forEach(orgKey => {
  var cpOrg = orgs[orgKey];
  var cpOrgCa = cas[cpOrg.certificateAuthorities[0]];
  var org = {
    name: orgKey, // Usually orgKey and mspid are equal, but in case they're different I'm guessing that this field is the key
    mspid: cpOrg.mspid, 
    username: cpOrgCa.registrar[0].enrollId,
    secret: cpOrgCa.registrar[0].enrollSecret,
    ca: {
      name: cpOrgCa.caName,
      url: cpOrgCa.url
    },
    'admin_cert': '<INSERT ADMIN CERT>',
    priv: '<INSERT PRIVATE KEY>',
    privateKeyPEM: '', // TODO: what should this value be?
    signedCertPEM: cpOrg.signedCert.pem, // TODO: verify this
    ordererID: ordKeys[0], // Should be indifferent to which key, there's only multiple orderers/CAs because of HA
    adminPath: ''
  };

  var cpOrgPeerKeys = peerKeys.filter(peerKey => peers[peerKey]['x-mspid'] === cpOrg.mspid );
  cpOrgPeerKeys.forEach(peerKey => {
    var cpOrgPeer = peers[peerKey];
    var peer = {
      requests: cpOrgPeer.url,
      events: cpOrgPeer.eventUrl,
      'server-hostname': null,
      'tls_cacerts': pteJson['test-network']['tls_cert']
    };
    org[peerKey] = peer;
  });

  pteJson['test-network'][orgKey] = org;
});

// Write to a file
// Uncomment the line below to see output in console
// console.log(util.inspect(pteJson, {colors: true, depth: null, maxArrayLength: null, breakLength: 100}));
fs.writeFile(path.join(__dirname, '../output/pte-config.json'), JSON.stringify(pteJson), 'utf8', (err) => {});
