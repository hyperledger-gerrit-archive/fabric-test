package k8s

import (
	"fmt"
	"strings"
	"reflect"

	"github.com/hyperledger/fabric-test/tools/operator/logger"
	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/connectionprofile"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
)

//K8sExternalIP -- To get the externalIP of a fabric component
func (k K8s) K8sExternalIP(input networkspec.Config, serviceName string) (string, error) {

	var IPAddress string
	var inputArgs []string
	if input.K8s.ServiceType == "NodePort" {
		inputArgs = []string{"get", "nodes", "-o", `jsonpath='{ $.items[*].status.addresses[?(@.type=="ExternalIP")].address }'`}
		k.Arguments = inputArgs
		output, err := client.ExecuteK8sCommand(k.Args(), false)
		if err != nil {
			logger.INFO("Failed to get the external IP for k8s using NodePor")
			return "", err
		}
		IPAddressList := strings.Split(string(output)[1:], " ")
		IPAddress = IPAddressList[0]
	} else if input.K8s.ServiceType == "LoadBalancer" {
		inputArgs = []string{"get", "-o", `jsonpath="{.status.loadBalancer.ingress[0].ip}"`, "services", serviceName}
		k.Arguments = inputArgs
		output, err := client.ExecuteK8sCommand(k.Args(), false)
		if err != nil {
			logger.INFO("Failed to get the external IP for k8s using NodePort")
			return "", err
		}
		IPAddress = string(output)[1 : len(string(output))-1]
	}

	return IPAddress, nil
}

//K8sServicePort -- To get the port number of a fabric k8s component
func (k K8s) K8sServicePort(serviceName, serviceType string, forHealth bool) (string, error) {
	var port string
	index := 0
	if forHealth {
		index = 1
	}
	input := []string{"get", "-o", fmt.Sprintf(`jsonpath="{.spec.ports[%v].nodePort}"`, index), "services", serviceName}
	k.Arguments = input
	output, err := client.ExecuteK8sCommand(k.Args(), false)
	if err != nil {
		logger.INFO("Failed to get the port number for service ", serviceName)
		return "", err
	}
	port = string(output)
	port = port[1 : len(port)-1]
	return port, nil
}

func (k K8s) ordererOrganizations(input networkspec.Config) (map[string]networkspec.Orderer, error) {
	orderers := make(map[string]networkspec.Orderer)
	artifactsLocation := input.ArtifactsLocation
	ordererOrgsPath := utils.OrdererOrgsDir(artifactsLocation)
	var err error
	var orderer networkspec.Orderer
	var portNumber, NodeIP string
	protocol := "grpc"
	if input.TLS == "true" || input.TLS == "mutual" {
		protocol = "grpcs"
	}
	for org := 0; org < len(input.OrdererOrganizations); org++ {
		ordererOrg := input.OrdererOrganizations[org]
		orgName := ordererOrg.Name
		for i := 0; i < ordererOrg.NumOrderers; i++ {
			ordererName := fmt.Sprintf("orderer%d-%s", i, orgName)
			portNumber, err = k.K8sServicePort(ordererName, input.K8s.ServiceType, false)
			if err != nil {
				return orderers, err
			}
			NodeIP, err = k.K8sExternalIP(input, ordererName)
			if err != nil {
				return orderers, err
			}
			orderer = networkspec.Orderer{MSPID: ordererOrg.MSPID, URL: fmt.Sprintf("%s://%s:%s", protocol, NodeIP, portNumber), AdminPath: utils.JoinPath(ordererOrgsPath, fmt.Sprintf("%s/users/Admin@%s/msp", orgName, orgName))}
			orderer.GrpcOptions.SslTarget = ordererName
			orderer.TLSCACerts.Path = utils.JoinPath(ordererOrgsPath, fmt.Sprintf("%s/orderers/%s.%s/msp/tlscacerts/tlsca.%s-cert.pem", orgName, ordererName, orgName, orgName))
			orderers[ordererName] = orderer
		}
	}
	return orderers, nil
}

func (k K8s) certificateAuthorities(peerOrg networkspec.PeerOrganizations, input networkspec.Config) (map[string]networkspec.CertificateAuthority, error) {
	CAs := make(map[string]networkspec.CertificateAuthority)
	var err error
	var CA networkspec.CertificateAuthority
	var portNumber, NodeIP string
	protocol := "http"
	if input.TLS == "true" || input.TLS == "mutual" {
		protocol = "https"
	}
	artifactsLocation := input.ArtifactsLocation
	orgName := peerOrg.Name
	for i := 0; i < peerOrg.NumCA; i++ {
		caName := fmt.Sprintf("ca%d-%s", i, orgName)
		portNumber, err = k.K8sServicePort(caName, input.K8s.ServiceType, false)
		if err != nil {
			return CAs, err
		}
		NodeIP, err = k.K8sExternalIP(input, caName)
		if err != nil {
			return CAs, err
		}
		CA = networkspec.CertificateAuthority{URL: fmt.Sprintf("%s://%s:%s", protocol, NodeIP, portNumber), CAName: caName}
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

func (k K8s) peersPerOrganization(peerorg networkspec.PeerOrganizations, input networkspec.Config) (map[string]networkspec.Peer, error) {
	var err error
	var peer networkspec.Peer
	var portNumber, NodeIP string
	peers := make(map[string]networkspec.Peer)
	protocol := "grpc"
	peerOrgsLocation := utils.PeerOrgsDir(input.ArtifactsLocation)
	if input.TLS == "true" || input.TLS == "mutual" {
		protocol = "grpcs"
	}
	for i := 0; i < peerorg.NumPeers; i++ {
		peerName := fmt.Sprintf("peer%d-%s", i, peerorg.Name)
		portNumber, err = k.K8sServicePort(peerName, input.K8s.ServiceType, false)
		if err != nil {
			return peers, err
		}
		NodeIP, err = k.K8sExternalIP(input, peerName)
		if err != nil {
			return peers, err
		}
		peer = networkspec.Peer{URL: fmt.Sprintf("%s://%s:%s", protocol, NodeIP, portNumber)}
		peer.GrpcOptions.SslTarget = peerName
		peer.TLSCACerts.Path = utils.JoinPath(peerOrgsLocation, fmt.Sprintf("%s/tlsca/tlsca.%s-cert.pem", peerorg.Name, peerorg.Name))
		peers[peerName] = peer
	}
	return peers, nil
}

//GenerateConnectionProfiles -- To generate conenction profiles
func (k K8s) GenerateConnectionProfiles(input networkspec.Config) error {

	orderersMap, err := k.ordererOrganizations(input)
	if err != nil {
		return err
	}
	connProfile := connectionprofile.ConnProfile{Orderers: orderersMap, Input: input}
	for org := 0; org < len(input.PeerOrganizations); org++ {
		organizations := make(map[string]networkspec.Organization)
		peerorg := input.PeerOrganizations[org]
		peersMap, err := k.peersPerOrganization(peerorg, input)
		if err != nil {
			return err
		}
		connProfile.Peers = peersMap
		ca, err := k.certificateAuthorities(peerorg, input)
		if err != nil {
			return err
		}
		connProfile.CA = ca
		caList := make([]string, 0, len(ca))
		for k := range ca {
			caList = append(caList, k)
		}
		org := connProfile.Organization(peerorg,  caList)
		organizations[peerorg.Name] = org
		err = connProfile.GenerateConnProfilePerOrg(peerorg.Name)
		if err != nil {
			logger.INFO("Failed to generate connection profile")
			return err
		}
	}
	return nil
}