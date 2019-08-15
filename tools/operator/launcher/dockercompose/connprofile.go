// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package dockercompose

import (
    "errors"
    "fmt"
    "strings"
	"reflect"

	"github.com/hyperledger/fabric-test/tools/operator/logger"
    "github.com/hyperledger/fabric-test/tools/operator/client"
    "github.com/hyperledger/fabric-test/tools/operator/utils"
    "github.com/hyperledger/fabric-test/tools/operator/networkspec"
    "github.com/hyperledger/fabric-test/tools/operator/connectionprofile"
)

//DockerExternalIP -- To get the externalIP of a fabric component
func (d DockerCompose) DockerExternalIP() string {
        return "localhost"
}

//DockerServicePort -- To get the port number of a docker container
func (d DockerCompose) DockerServicePort(serviceName string, forHealth bool) (string, error) {

	var port string
    args := []string{"port", serviceName}
    output, err := client.ExecuteCommand("docker", args, false)
    if err != nil {
        logger.INFO("Failed to get the port number for service ", serviceName)
        return "", err
    }
    ports := strings.Split(string(output), "\n")
    if len(ports) == 0 {
		logger.INFO("Unable to get the port number for service ", serviceName)
        return "", errors.New("Unable to get the port number")
    }
    if forHealth {
        for i := 0; i < len(ports); i++ {
            if (strings.Contains(ports[i], "9443")) || (strings.Contains(ports[i], "8443")) {
                port = ports[i]
                break
            }
        }
    } else {
        for i := 0; i < len(ports); i++ {
            if !(strings.Contains(ports[i], "9443")) {
                if !(strings.Contains(ports[i], "8443")) {
                    port = ports[i]
                    break
                }
            }
        }
    }
    port = port[len(port)-5 : len(port)]
    return port, nil
}

//OrdererOrgs --
func (d DockerCompose) ordererOrgs(input networkspec.Config) (map[string]networkspec.Orderer, error) {

	orderers := make(map[string]networkspec.Orderer)
	artifactsLocation := input.ArtifactsLocation
	ordererOrgsPath := utils.OrdererOrgsDir(artifactsLocation)
	var err error
	var orderer networkspec.Orderer
	var portNumber string
	nodeIP := d.DockerExternalIP()
	protocol := "grpc"
	if input.TLS == "true" || input.TLS == "mutual" {
		protocol = "grpcs"
	}
	for org := 0; org < len(input.OrdererOrganizations); org++ {
		ordererOrg := input.OrdererOrganizations[org]
		orgName := ordererOrg.Name
		for i := 0; i < ordererOrg.NumOrderers; i++ {
			ordererName := fmt.Sprintf("orderer%d-%s", i, orgName)
			portNumber, err = d.DockerServicePort(ordererName, false)
			if err != nil {
				return orderers, err
			}
			orderer = networkspec.Orderer{MSPID: ordererOrg.MSPID, URL: fmt.Sprintf("%s://%s:%s", protocol, nodeIP, portNumber), AdminPath: utils.JoinPath(ordererOrgsPath, fmt.Sprintf("%s/users/Admin@%s/msp", orgName, orgName))}
			orderer.GrpcOptions.SslTarget = ordererName
			orderer.TLSCACerts.Path = utils.JoinPath(ordererOrgsPath, fmt.Sprintf("%s/orderers/%s.%s/msp/tlscacerts/tlsca.%s-cert.pem", orgName, ordererName, orgName, orgName))
			orderers[ordererName] = orderer
		}
	}
	return orderers, nil
}

//CertificateAuthorities --
func (d DockerCompose) certificateAuthorities(peerOrg networkspec.PeerOrganizations, input networkspec.Config) (map[string]networkspec.CertificateAuthority, error) {

	CAs := make(map[string]networkspec.CertificateAuthority)
	var err error
	var CA networkspec.CertificateAuthority
	var portNumber string
	nodeIP := d.DockerExternalIP()
	protocol := "http"
	if input.TLS == "true" || input.TLS == "mutual" {
		protocol = "https"
	}
	artifactsLocation := input.ArtifactsLocation
	orgName := peerOrg.Name
	for i := 0; i < peerOrg.NumCA; i++ {
		caName := fmt.Sprintf("ca%d-%s", i, orgName)
		portNumber, err = d.DockerServicePort(caName, false)
		if err != nil {
			return CAs, err
		}
		CA = networkspec.CertificateAuthority{URL: fmt.Sprintf("%s://%s:%s", protocol, nodeIP, portNumber), CAName: caName}
		CA.TLSCACerts.Path = utils.JoinPath(utils.PeerOrgsDir(artifactsLocation), fmt.Sprintf("%s/ca/ca.%s-cert.pem", orgName, orgName))
		CA.HTTPOptions.Verify = false
		CA.Registrar.EnrollID, CA.Registrar.EnrollSecret = "admin", "adminpw"
		CAs[fmt.Sprintf("ca%d", i)] = CA
	}
	return CAs, nil
}

func getKeysFromMap(newMap interface{}) []string {

	var componentsList []string
	v := reflect.ValueOf(newMap)
	if v.Kind() != reflect.Map {
		logger.INFO("not a map!")
		return nil
	}
	keys := v.MapKeys()
	for i := range keys {
		componentsList = append(componentsList, fmt.Sprintf("%s", keys[i]))
	}
	return componentsList
}

//PeersPerOrganization --
func (d DockerCompose) peersPerOrganization(peerorg networkspec.PeerOrganizations, input networkspec.Config) (map[string]networkspec.Peer, error) {

	var err error
	var peer networkspec.Peer
	var portNumber string
	nodeIP := d.DockerExternalIP()
    peerOrgsLocation := utils.PeerOrgsDir(input.ArtifactsLocation)
	peers := make(map[string]networkspec.Peer)
	protocol := "grpc"
	if input.TLS == "true" || input.TLS == "mutual" {
		protocol = "grpcs"
	}
	for i := 0; i < peerorg.NumPeers; i++ {
		peerName := fmt.Sprintf("peer%d-%s", i, peerorg.Name)
		portNumber, err = d.DockerServicePort(peerName, false)
		if err != nil {
			return peers, err
		}
		peer = networkspec.Peer{URL: fmt.Sprintf("%s://%s:%s", protocol, nodeIP, portNumber)}
		peer.GrpcOptions.SslTarget = peerName
		peer.TLSCACerts.Path = utils.JoinPath(peerOrgsLocation, fmt.Sprintf("%s/tlsca/tlsca.%s-cert.pem", peerorg.Name, peerorg.Name))
		peers[peerName] = peer
	}
	return peers, nil
}

//GenerateConnectionProfiles -- To generate conenction profiles
func (d DockerCompose) GenerateConnectionProfiles(input networkspec.Config) error {

	orderersMap, err := d.ordererOrgs(input)
	if err != nil {
		return err
    }
    connProfile := connectionprofile.ConnProfile{Orderers: orderersMap, Input: input}
	for org := 0; org < len(input.PeerOrganizations); org++ {
		organizations := make(map[string]networkspec.Organization)
		peerorg := input.PeerOrganizations[org]
		peersMap, err := d.peersPerOrganization(peerorg, input)
		if err != nil {
			return err
        }
        connProfile.Peers = peersMap
		ca, err := d.certificateAuthorities(peerorg, input)
		if err != nil {
			return err
        }
        connProfile.CA = ca
		caList := make([]string, 0, len(ca))
		for k := range ca {
			caList = append(caList, k)
		}
		org := connProfile.Organization(peerorg, caList)
        organizations[peerorg.Name] = org
        connProfile.Organizations = organizations
		err = connProfile.GenerateConnProfilePerOrg(peerorg.Name)
		if err != nil {
			logger.INFO("Failed to generate connection profile")
			return err
		}
	}
	return nil
}