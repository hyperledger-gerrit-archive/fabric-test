// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package connectionprofile

import (
	"fmt"
	"io/ioutil"
	"os"

	"github.com/hyperledger/fabric-test/tools/operator/logger"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
	yaml "gopkg.in/yaml.v2"
)

type ConnProfile struct{
	Peers         map[string]networkspec.Peer
	Orderers      map[string]networkspec.Orderer
	CA            map[string]networkspec.CertificateAuthority
	Organizations map[string]networkspec.Organization
	Config         networkspec.Config
}

func (c ConnProfile) Organization(peerorg networkspec.PeerOrganizations, caList []string) networkspec.Organization {

	var organization networkspec.Organization
	peerOrgsLocation := utils.PeerOrgsDir(c.Config.ArtifactsLocation)
	path := utils.JoinPath(peerOrgsLocation, fmt.Sprintf("%s/users/Admin@%s/msp", peerorg.Name, peerorg.Name))
	organization = networkspec.Organization{Name: peerorg.Name, MSPID: peerorg.MSPID}
	organization.AdminPrivateKey.Path = path
	organization.SignedCert.Path = path
	organization.CertificateAuthorities = append(organization.CertificateAuthorities, caList...)
	organization.Peers = append(organization.Peers, utils.GetKeysFromMap(c.Peers)...)
	return organization
}

func (c ConnProfile) GenerateConnProfilePerOrg(orgName string) error {

	var err error
	path := utils.ConnectionProfilesDir(c.Config.ArtifactsLocation)
	fileName := utils.JoinPath(path, fmt.Sprintf("connection_profile_%s.yaml", orgName))
	channels := make(map[string]networkspec.Channel)
	for i := 0; i < c.Config.NumChannels; i++ {
		var channel networkspec.Channel
		orderersList := utils.GetKeysFromMap(c.Orderers)
		peersList := utils.GetKeysFromMap(c.Peers)
		channel = networkspec.Channel{Orderers: orderersList, Peers: peersList}
		channelName := fmt.Sprintf("testorgschannel%d", i)
		channels[channelName] = channel
	}
	client := networkspec.Client{Organization: orgName}
	client.Conenction.Timeout.Peer.Endorser = 300
	client.Conenction.Timeout.Peer.EventHub = 600
	client.Conenction.Timeout.Peer.EventReg = 300
	client.Conenction.Timeout.Orderer = 300
	cp := networkspec.ConnectionProfile{Client: client, Channels: channels, Organizations: c.Organizations, Orderers: c.Orderers, Peers: c.Peers, CA: c.CA}
	yamlBytes, err := yaml.Marshal(cp)
	if err != nil {
		logger.ERROR("Failed to convert the connection profile struct to bytes")
		return err
	}
	_, err = os.Create(fileName)
	if err != nil {
		logger.ERROR("Failed to create ", fileName)
		return err
	}
	yamlBytes = append([]byte("version: 1.0 \nname: My network \ndescription: Connection Profile for Blockchain Network \n"), yamlBytes...)
	err = ioutil.WriteFile(fileName, yamlBytes, 0644)
	if err != nil {
		logger.ERROR("Failed to write content to ", fileName)
		return err
	}
	logger.INFO("Successfully created ", fileName)
	return nil
}