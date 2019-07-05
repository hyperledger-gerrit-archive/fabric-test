package nl

import (
    "fmt"
    "io/ioutil"
    "os"
    "os/exec"
    "path/filepath"
    "reflect"
    "strings"
//    "github.com/hyperledger/fabric-test/tools/NL/k8s/"
    yaml "gopkg.in/yaml.v2"
)

func getK8sExternalIp(kubeconfigPath string, networkSpec Config) string {

    var IPAddress string
    if networkSpec.K8s.ServiceType == "NodePort" {
        stdoutStderr, err := exec.Command("kubectl", fmt.Sprintf("--kubeconfig=%v", kubeconfigPath), "get", "nodes", "-o", `jsonpath='{ $.items[*].status.addresses[?(@.type=="ExternalIP")].address }'`).CombinedOutput()
        if err != nil {
            fmt.Println("error is %v", string(stdoutStderr))
        }
        IPAddressList := strings.Split(string(stdoutStderr)[1:], " ")
        IPAddress = IPAddressList[0]
    }
    return IPAddress
}

func getK8sServicePort(kubeconfigPath, serviceName string) string {
    stdoutStderr, err := exec.Command("kubectl", fmt.Sprintf("--kubeconfig=%v", kubeconfigPath), "get", "-o", `jsonpath="{.spec.ports[0].nodePort}"`, "services", serviceName).CombinedOutput()
    if err != nil {
        fmt.Println("error is %v", string(stdoutStderr))
    }
    port := string(stdoutStderr)
    return port[1 : len(port)-1]
}

func ordererOrganizations(networkSpec Config, kubeconfigPath string) map[string]Orderer {
    orderers := make(map[string]Orderer)
    k8sNodeIp := getK8sExternalIp(kubeconfigPath, networkSpec)
    for org := range networkSpec.OrdererOrganizations {
        ordererOrg := networkSpec.OrdererOrganizations[org]
        orgName := ordererOrg.Name
        for i := 0; i < ordererOrg.NumOrderers; i++ {
            var orderer Orderer
            ordererName := fmt.Sprintf("orderer%v-%v", i, orgName)
            var portNumber string
            if networkSpec.K8s.ServiceType == "NodePort"{
                portNumber = getK8sServicePort(kubeconfigPath, ordererName)
            }else{
                portNumber = "7053"
            }
            orderer = Orderer{MSPID: ordererOrg.MspID, Url: fmt.Sprintf("grpcs://%v:%v", k8sNodeIp, portNumber), AdminPath: filepath.Join(networkSpec.ArtifactsLocation, fmt.Sprintf("/crypto-config/ordererOrganizations/%v/users/Admin@%v/msp", ordererOrg.Name, ordererOrg.Name))}
            orderer.GrpcOptions.SslTarget = ordererName
            orderer.TlsCACerts.Path = filepath.Join(networkSpec.ArtifactsLocation, fmt.Sprintf("/crypto-config/ordererOrganizations/%v/orderers/%v.%v/msp/tlscacerts/tlsca.%v-cert.pem", orgName, ordererName, orgName, orgName))
            orderers[ordererName] = orderer
        }
    }
    return orderers
}

func CertificateAuthorities(peerOrg PeerOrganizations, kubeconfigPath string, networkSpec Config) map[string]CertificateAuthority {
    cas := make(map[string]CertificateAuthority)
    k8sNodeIp := getK8sExternalIp(kubeconfigPath, networkSpec)
    artifacts_location := networkSpec.ArtifactsLocation
    for i := 0; i < peerOrg.NumCa; i++ {
        var ca CertificateAuthority
        var portNumber string
        orgName := peerOrg.Name
        caName := fmt.Sprintf("ca%v-%v", i, orgName)
        if networkSpec.K8s.ServiceType == "NodePort"{
            portNumber = getK8sServicePort(kubeconfigPath, caName)
        }else{
            portNumber = "7053"
        }
        ca = CertificateAuthority{Url: fmt.Sprintf("grpcs://%v:%v", k8sNodeIp, portNumber), CAName: caName}
        ca.TlsCACerts.Path = filepath.Join(artifacts_location, fmt.Sprintf("/crypto-config/peerOrganizations/%v/ca/ca.%v-cert.pem", orgName, orgName))
        ca.HttpOptions.Verify = false
        ca.Registrar.EnrollId = "admin"
        ca.Registrar.EnrollSecret = "adminpw"
        cas[fmt.Sprintf("ca%v", i)] = ca
    }
    return cas
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

func peerOrganizations(networkSpec Config, kubeconfigPath string) error{

    k8sNodeIp := getK8sExternalIp(kubeconfigPath, networkSpec)
    for org := 0; org < len(networkSpec.PeerOrganizations); org++ {
        peers := make(map[string]Peer)
        organizations := make(map[string]Organization)
        peerorg := networkSpec.PeerOrganizations[org]
        var peer Peer
        var organization Organization
        peersList := []string{}
        for i := 0; i < networkSpec.PeerOrganizations[org].NumPeers; i++ {
            peerName := fmt.Sprintf("peer%v-%v", i, peerorg.Name)
            var portNumber string
            if networkSpec.K8s.ServiceType == "NodePort"{
                portNumber = getK8sServicePort(kubeconfigPath, peerName)
            }else{
                portNumber = "7053"
            }
            peer = Peer{Url: fmt.Sprintf("grpcs://%v:%v", k8sNodeIp, portNumber)}
            peer.GrpcOptions.SslTarget = peerName
            peer.TlsCACerts.Path = filepath.Join(networkSpec.ArtifactsLocation, fmt.Sprintf("/crypto-config/peerOrganizations/%v/tlsca/tlsca.%v-cert.pem", peerorg.Name, peerorg.Name))
            peersList = append(peersList, peerName)
            peers[peerName] = peer
            organization = Organization{Name: peerorg.Name, MSPID: peerorg.MspID}
        }
        path := filepath.Join(networkSpec.ArtifactsLocation, fmt.Sprintf("/crypto-config/peerOrganizations/%v/users/Admin@%v/msp", peerorg.Name, peerorg.Name))
        organization.AdminPrivateKey.Path = path
        organization.SignedCert.Path = path
        ca := CertificateAuthorities(peerorg, kubeconfigPath, networkSpec)
        caList := make([]string, 0, len(ca))
        for k := range ca {
            caList = append(caList, k)
        }
        organization.CertificateAuthorities = append(organization.CertificateAuthorities, caList...)
        organization.Peers = append(organization.Peers, peersList...)
        organizations[peerorg.Name] = organization

        err := generateConnectionProfileFile(kubeconfigPath, peerorg.Name, networkSpec, peers, organizations, ca)
        if err != nil{
            return fmt.Errorf("Failed to generate connection profile; err: %v", err)
        }
    }
    return nil
}

func generateConnectionProfileFile(kubeconfigPath, orgName string, networkSpec Config, peerOrganizations map[string]Peer, organizations map[string]Organization, certificateAuthorities map[string]CertificateAuthority) error{

    fileName := fmt.Sprintf("connection_profile_%v.yaml", orgName)
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
    fmt.Println("Successfully created",fileName)
    return nil
}

func CreateConnectionProfile(networkSpec Config, kubeconfigPath string) error{
    err := peerOrganizations(networkSpec, kubeconfigPath)
    if err != nil{
        return fmt.Errorf("Error occured while generating the connection profile files; err: %v", err)
    }
    return nil
}