// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"time"
	yaml "gopkg.in/yaml.v2"
)

func getK8sExternalIP(kubeconfigPath string, networkSpec Config, serviceName string) string {

	var IPAddress string
	if networkSpec.K8s.ServiceType == "NodePort" {
		stdoutStderr, err := exec.Command("kubectl", fmt.Sprintf("--kubeconfig=%v", kubeconfigPath), "get", "nodes", "-o", `jsonpath='{ $.items[*].status.addresses[?(@.type=="ExternalIP")].address }'`).CombinedOutput()
		if err != nil {
			fmt.Println("error is", string(stdoutStderr))
		}
		IPAddressList := strings.Split(string(stdoutStderr)[1:], " ")
		IPAddress = IPAddressList[0]
	} else if networkSpec.K8s.ServiceType == "LoadBalancer" {
		stdoutStderr, err := exec.Command("kubectl", fmt.Sprintf("--kubeconfig=%v", kubeconfigPath), "get", "-o", `jsonpath="{.status.loadBalancer.ingress[0].ip}"`, "services", serviceName).CombinedOutput()
		if err != nil {
			fmt.Println("error is", string(stdoutStderr))
		}
		IPAddress = string(stdoutStderr)[1 : len(string(stdoutStderr))-1]
	}
	return IPAddress
}

func getK8sServicePort(kubeconfigPath, serviceName string) string {
	stdoutStderr, err := exec.Command("kubectl", fmt.Sprintf("--kubeconfig=%v", kubeconfigPath), "get", "-o", `jsonpath="{.spec.ports[0].nodePort}"`, "services", serviceName).CombinedOutput()
	if err != nil {
		fmt.Println("error is", string(stdoutStderr))
	}
	port := string(stdoutStderr)
	return port[1 : len(port)-1]
}

func ordererOrganizations(networkSpec Config, kubeconfigPath string) map[string]Orderer {
	orderers := make(map[string]Orderer)
	numOrdererOrganizations := len(networkSpec.OrdererOrganizations)
	if networkSpec.Orderer.OrdererType == "solo" || networkSpec.Orderer.OrdererType == "kafka" {
		numOrdererOrganizations = 1
	}

	for org := 0; org < numOrdererOrganizations; org++ {
		ordererOrg := networkSpec.OrdererOrganizations[org]
		orgName := ordererOrg.Name
		numOrderers := ordererOrg.NumOrderers
		if networkSpec.Orderer.OrdererType == "solo" {
			numOrderers = 1
		}
		for i := 0; i < numOrderers; i++ {
			var orderer Orderer
			ordererName := fmt.Sprintf("orderer%v-%v", i, orgName)
			var portNumber, k8sNodeIP, protocol string
			if networkSpec.K8s.ServiceType == "NodePort" {
				portNumber = getK8sServicePort(kubeconfigPath, ordererName)
				k8sNodeIP = getK8sExternalIP(kubeconfigPath, networkSpec, "")
			} else {
				portNumber = "7050"
				k8sNodeIP = getK8sExternalIP(kubeconfigPath, networkSpec, ordererName)
			}
			protocol = "grpc"
			if networkSpec.TLS == "true" || networkSpec.TLS == "enabled"{
				protocol = "grpcs"
			}
			orderer = Orderer{MSPID: ordererOrg.MSPID, URL: fmt.Sprintf("%v://%v:%v", protocol, k8sNodeIP, portNumber), AdminPath: filepath.Join(networkSpec.ArtifactsLocation, fmt.Sprintf("/crypto-config/ordererOrganizations/%v/users/Admin@%v/msp", ordererOrg.Name, ordererOrg.Name))}
			orderer.GrpcOptions.SslTarget = ordererName
			orderer.TLSCACerts.Path = filepath.Join(networkSpec.ArtifactsLocation, fmt.Sprintf("/crypto-config/ordererOrganizations/%v/orderers/%v.%v/msp/tlscacerts/tlsca.%v-cert.pem", orgName, ordererName, orgName, orgName))
			orderers[ordererName] = orderer
		}
	}
	return orderers
}

func certificateAuthorities(peerOrg PeerOrganizations, kubeconfigPath string, networkSpec Config) map[string]CertificateAuthority {
	CAs := make(map[string]CertificateAuthority)
	artifactsLocation := networkSpec.ArtifactsLocation
	for i := 0; i < peerOrg.NumCA; i++ {
		var CA CertificateAuthority
		var portNumber, k8sNodeIP, protocol string
		orgName := peerOrg.Name
		caName := fmt.Sprintf("ca%v-%v", i, orgName)
		if networkSpec.K8s.ServiceType == "NodePort" {
			portNumber = getK8sServicePort(kubeconfigPath, caName)
			k8sNodeIP = getK8sExternalIP(kubeconfigPath, networkSpec, "")
		} else {
			portNumber = "7054"
			k8sNodeIP = getK8sExternalIP(kubeconfigPath, networkSpec, caName)
		}
		protocol = "http"
			if networkSpec.TLS == "true" || networkSpec.TLS == "enabled"{
				protocol = "https"
			}
		CA = CertificateAuthority{URL: fmt.Sprintf("%v://%v:%v", protocol, k8sNodeIP, portNumber), CAName: caName}
		CA.TLSCACerts.Path = filepath.Join(artifactsLocation, fmt.Sprintf("/crypto-config/peerOrganizations/%v/ca/ca.%v-cert.pem", orgName, orgName))
		CA.HTTPOptions.Verify = false
		CA.Registrar.EnrollID = "admin"
		CA.Registrar.EnrollSecret = "adminpw"
		CAs[fmt.Sprintf("ca%v", i)] = CA
	}
	return CAs
}

func getKeysFromMap(newMap interface{}) []string {
	var componentsList []string
	v := reflect.ValueOf(newMap)
	if v.Kind() != reflect.Map {
		fmt.Println("not a map!")
		return nil
	}
	keys := v.MapKeys()
	for i := range keys {
		componentsList = append(componentsList, fmt.Sprintf("%v", keys[i]))
	}
	return componentsList
}

func peerOrganizations(networkSpec Config, kubeconfigPath string) error {

	for org := 0; org < len(networkSpec.PeerOrganizations); org++ {
		peers := make(map[string]Peer)
		organizations := make(map[string]Organization)
		peerorg := networkSpec.PeerOrganizations[org]
		var peer Peer
		var organization Organization
		peersList := []string{}
		for i := 0; i < networkSpec.PeerOrganizations[org].NumPeers; i++ {
			peerName := fmt.Sprintf("peer%v-%v", i, peerorg.Name)
			var portNumber, k8sNodeIP, protocol string
			if networkSpec.K8s.ServiceType == "NodePort" {
				portNumber = getK8sServicePort(kubeconfigPath, peerName)
				k8sNodeIP = getK8sExternalIP(kubeconfigPath, networkSpec, "")
			} else {
				portNumber = "7051"
				k8sNodeIP = getK8sExternalIP(kubeconfigPath, networkSpec, peerName)
			}
			protocol = "grpc"
			if networkSpec.TLS == "true" || networkSpec.TLS == "enabled"{
				protocol = "grpcs"
			}
			peer = Peer{URL: fmt.Sprintf("%v://%v:%v", protocol, k8sNodeIP, portNumber)}
			peer.GrpcOptions.SslTarget = peerName
			peer.TLSCACerts.Path = filepath.Join(networkSpec.ArtifactsLocation, fmt.Sprintf("/crypto-config/peerOrganizations/%v/tlsca/tlsca.%v-cert.pem", peerorg.Name, peerorg.Name))
			peersList = append(peersList, peerName)
			peers[peerName] = peer
			organization = Organization{Name: peerorg.Name, MSPID: peerorg.MSPID}
		}
		path := filepath.Join(networkSpec.ArtifactsLocation, fmt.Sprintf("/crypto-config/peerOrganizations/%v/users/Admin@%v/msp", peerorg.Name, peerorg.Name))
		organization.AdminPrivateKey.Path = path
		organization.SignedCert.Path = path
		ca := certificateAuthorities(peerorg, kubeconfigPath, networkSpec)
		caList := make([]string, 0, len(ca))
		for k := range ca {
			caList = append(caList, k)
		}
		organization.CertificateAuthorities = append(organization.CertificateAuthorities, caList...)
		organization.Peers = append(organization.Peers, peersList...)
		organizations[peerorg.Name] = organization

		err := generateConnectionProfileFile(kubeconfigPath, peerorg.Name, networkSpec, peers, organizations, ca)
		if err != nil {
			return fmt.Errorf("Failed to generate connection profile; err: %v", err)
		}
	}
	return nil
}

func generateConnectionProfileFile(kubeconfigPath, orgName string, networkSpec Config, peerOrganizations map[string]Peer, organizations map[string]Organization, certificateAuthorities map[string]CertificateAuthority) error {

	path := filepath.Join(networkSpec.ArtifactsLocation, "connection-profile")
	_ = os.Mkdir(path, 0755)

	fileName := filepath.Join(path, fmt.Sprintf("connection_profile_%v.yaml", orgName))
	channels := make(map[string]Channel)
	orderersMap := ordererOrganizations(networkSpec, kubeconfigPath)
	for i := 0; i < networkSpec.NumChannels; i++ {
		var channel Channel
		orderersList := getKeysFromMap(orderersMap)
		peersList := getKeysFromMap(peerOrganizations)
		channel = Channel{Orderers: orderersList, Peers: peersList}
		channelName := fmt.Sprintf("testorgschannel%v", i)
		channels[channelName] = channel
	}
	client := Client{Organization: orgName}
	client.Conenction.Timeout.Peer.Endorser = 300
	client.Conenction.Timeout.Peer.EventHub = 600
	client.Conenction.Timeout.Peer.EventReg = 300
	client.Conenction.Timeout.Orderer = 300
	cp := ConnectionProfile{Client: client, Channels: channels, Organizations: organizations, Orderers: orderersMap, Peers: peerOrganizations, CA: certificateAuthorities}
	yamlBytes, err := yaml.Marshal(cp)
	if err != nil {
		return fmt.Errorf("Failed to convert the connection profile struct to bytes; err: %v", err)
	}
	_, err = os.Create(fileName)
	if err != nil {
		return fmt.Errorf("Failed to create %v file; err:%v", fileName, err)
	}
	yamlBytes = append([]byte("version: 1.0 \nname: My network \ndescription: Connection Profile for Blockchain Network \n"), yamlBytes...)
	err = ioutil.WriteFile(fileName, yamlBytes, 0644)
	if err != nil {
		return fmt.Errorf("Failed to write content to %v file; err:%v", fileName, err)
	}
	fmt.Println("Successfully created", fileName)
	return nil
}

//CreateConnectionProfile - to generate connection profile
func CreateConnectionProfile(networkSpec Config, kubeconfigPath string) error {
	time.Sleep(5 * time.Second)
	err := peerOrganizations(networkSpec, kubeconfigPath)
	if err != nil {
		return fmt.Errorf("Error occured while generating the connection profile files; err: %v", err)
	}
	return nil
}