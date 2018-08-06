/**
 * Copyright 2018 IBM All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

// This script takes in multiple connection profile JSON files that are expected to belong to
//  a single network, where each connection profile JSON file is named with a prefix of `creds`.
//  Furthermore, this script expects that ALL of the `creds*.json` files inside `../config/`
//  belong to a single network.

'use strict';

const util = require('util');
const fs = require('fs');
const path = require('path');

// Get all filenames that start with `creds`
var cpFilenames = fs.readdirSync(path.join(__dirname, '../config/')).filter(filename => filename.startsWith("creds"));
var cpJsons = [];
cpFilenames.forEach(filename => {
  cpJsons.push(require('../config/' + filename)); // Push each connection profile JSON object into cpJsons
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

ordKeys.forEach(ordKey => {
  var cpOrd = orderers[ordKey];

  var ord = {
    name: 'OrdererOrg',
    mspid: 'OrdererOrg',
    mspPath: null,
    adminPath: null,
    comName: null,
    url: cpOrd.url,
    'server-hostname': null, // Default value, can change
    tls_cacerts: null // Default value, can change
  };

  if (cpOrd.grpcOptions != null) {
    // Nesting if-statements instead of combining conditions so that more grpc options can be
    //  accounted for if required
    if (cpOrd.grpcOptions['ssl-target-name-override'] != null)
      ord['server-hostname'] = cpOrd.grpcOptions['ssl-target-name-override'];
  }

  if (cpOrd.tlsCACerts.pem != null) ord.tls_cacerts = cpOrd.tlsCACerts.pem;
  else ord.tls_cacerts = cpOrd.tlsCACerts.path;

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
    'admin_cert': null, // Default value, can change
    priv: null, // Default value, can change
    adminPath: null, // Default value, can change
    ordererID: ordKeys[0] // Should be indifferent to which key, there's only multiple orderers/CAs because of HA
  };

  // Assumption: private key and signed certs BOTH contain either PEMs or paths, not a mix of the two
  var pathsNotPems = false;

  if (cpOrg.adminPrivateKey != null) {
    if (cpOrg.adminPrivateKey.pem != null) org.priv = cpOrg.adminPrivateKey.pem;
    else pathsNotPems = true;
  }

  if (cpOrg.signedCert != null) {
    if (cpOrg.signedCert.pem != null) org['admin_cert'] = cpOrg.signedCert.pem;
    else pathsNotPems = true;
  }

  // Assumption: if paths are used, then both admin private key and signed cert are guaranteed to be non-null
  if (pathsNotPems == true) {
    // If pathsNotPems is true, then (given the above assumption) both cpOrg.adminPrivateKey and cpOrg.signedCert are
    //  guaranteed to be non-null
    var paths = [cpOrg.adminPrivateKey.path, cpOrg.signedCert.path].sort();

    // Starting at the first character of both strings, iterate through the strings' characters and compare until the characters
    //  do not match
    var i = 0, length = paths[0].length;
    while (i < length && paths[0].charAt(i) === paths[1].charAt(i)) i++;

    // Set admin path to the common portion of the two paths; this should resolve to the location of the msp directory,
    //  as the signed cert is found under /path/to/msp/signcerts/... and the private key is under /path/to/msp/keystore/...
    //  so the common portion is /path/to/msp
    org.adminPath = paths[0].substring(0, i);
  }

  var cpOrgPeerKeys = peerKeys.filter(peerKey => peers[peerKey]['x-mspid'] === cpOrg.mspid );
  cpOrgPeerKeys.forEach(peerKey => {
    var cpOrgPeer = peers[peerKey];
    var peer = {
      requests: cpOrgPeer.url,
      events: cpOrgPeer.eventUrl,
      'server-hostname': null // Default value, can change as seen below
    };

    if (cpOrgPeer.grpcOptions != null) {
      // Nesting if-statements instead of combining conditions so that more grpc options can be
      //  accounted for if required
      if (cpOrgPeer.grpcOptions['ssl-target-name-override'] != null)
        peer['server-hostname'] = cpOrgPeer.grpcOptions['ssl-target-name-override'];
    }

    if (cpOrgPeer.tlsCACerts.pem != null)
      peer.tls_cacerts = cpOrgPeer.tlsCACerts.pem;
    else
      peer.tls_cacerts = cpOrgPeer.tlsCACerts.path;

    org[peerKey] = peer;
  });

  pteJson['test-network'][orgKey] = org;
});

// Write to a file
// Uncomment the line below to see output in console
// console.log(util.inspect(pteJson, {colors: true, depth: null, maxArrayLength: null, breakLength: 100}));
fs.writeFile(path.join(__dirname, '../output/pte-config.json'), JSON.stringify(pteJson), 'utf8', (err) => {});
