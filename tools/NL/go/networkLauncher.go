package main

import (
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"text/template"

	"github.com/hyperledger/fabric-test/tools/NL/go/templates"
	yaml "gopkg.in/yaml.v2"
)

type NetworkLauncher struct {
}

// Config Struct
type Config struct {
	DbType               string                 `yaml:"db_type,omitempty"`
	PeerLoggingSPec      string                 `yaml:"peer_fabric_logging_spec,omitempty"`
	OrdererLoggingSPec   string                 `yaml:"orderer_fabric_logging_spec,omitempty"`
	TLS                  string                 `yaml:"tls,omitempty"`
	Metrics              bool                   `yaml:"metrics,omitempty"`
	ArtifactsLocation    string                 `yaml:"certs_location,omitempty"`
	OrdererConfig        OrdererConfig          `yaml:"orderer,omitempty"`
	KafkaConfig          KafkaConfig            `yaml:"kafka,omitempty"`
	OrdererOrganizations []OrdererOrganizations `yaml:"orderer_organizations,omitempty"`
	PeerOrganizations    []PeerOrganizations    `yaml:"peer_organizations,omitempty"`
	NumChannels          int                    `yaml:"num_channels,omitempty"`
}

type CryptoConfig struct {
	OrdererOrganizations []OrdererOrganizations `yaml:"orderer_organizations,omitempty"`
	PeerOrganizations    []PeerOrganizations    `yaml:"peer_organizations,omitempty"`
	OrdererHosts         map[string][]string    `yaml:"orderer_hosts,omitempty"`
	PeerHosts            map[string][]string    `yaml:"peer_hosts,omitempty"`
}

type K8sServices struct {
	OrdererOrganizations []OrdererOrganizations `yaml:"orderer_organizations,omitempty"`
	PeerOrganizations    []PeerOrganizations    `yaml:"peer_organizations,omitempty"`
}

type FabricK8sPods struct {
	Organizations       map[string]interface{}      `yaml:"orderer_organizations,omitempty"`
}

type ConfigTx struct {
	OrdererOrganizations []OrdererOrganizations `yaml:"orderer_organizations,omitempty"`
	PeerOrganizations    []PeerOrganizations    `yaml:"peer_organizations,omitempty"`
	OrdererAddresses     []string               `yaml:"orderer_addresses,omitempty"`
	OrdererConfig        OrdererConfig          `yaml:"orderer,omitempty"`
	OrdererCerts         []OrdererCert          `yaml:"orderer_certs,omitempty"`
	ArtifactsLocation    string                 `yaml:"certs_location,omitempty"`
}

type OrdererCert struct {
	Host            string `yaml:"host,omitempty"`
	TlsCertLocation string `yaml:"tls_cert_location,omitempty"`
}

// OrdererConfig struct
type OrdererConfig struct {
	OrdererType string
	Batchsize   struct {
		Maxmessagecount   int    `yaml:"maxmessagecount,omitempty"`
		Absolutemaxbytes  string `yaml:"absolutemaxbytes,omitempty"`
		Preferredmaxbytes string `yaml:"preferredmaxbytes,omitempty"`
	} `yaml:"batchsize,omitempty"`
	Batchtimeout    string
	Etcdraftoptions struct {
		TickInterval         string `yaml:"TickInterval,omitempty"`
		ElectionTick         int    `yaml:"ElectionTick,omitempty"`
		HeartbeatTick        int    `yaml:"HeartbeatTick,omitempty"`
		MaxInflightBlocks    int    `yaml:"MaxInflightBlocks,omitempty"`
		SnapshotIntervalSize string `yaml:"SnapshotIntervalSize,omitempty"`
	} `yaml:"etcdraft_options,omitempty"`
}

// OrdererOrganizations struct
type OrdererOrganizations struct {
	Name        string `yaml:"name,omitempty"`
	MspId       string `yaml:"msp_id,omitempty"`
	NumOrderers int    `yaml:"num_orderers,omitempty"`
	NumCa       int    `yaml:"num_ca,omitempty"`
}

// KafkaConfig struct
type KafkaConfig struct {
	NumKafka             int `yaml:"num_kafka,omitempty"`
	NumKafkaReplications int `yaml:"num_kafka_replications,omitempty"`
	NumZookeepers        int `yaml:"num_zookeepers,omitempty"`
}

// PeerOrganizations stuct
type PeerOrganizations struct {
	Name     string `yaml:"name,omitempty"`
	MspId    string `yaml:"msp_id,omitempty"`
	NumPeers int    `yaml:"num_peers,omitempty"`
	NumCa    int    `yaml:"num_ca,omitempty"`
}

func (n *NetworkLauncher) getConf(networkSpecPath string) Config {
	var config Config
	yamlFile, err := ioutil.ReadFile(networkSpecPath)
	if err != nil {
		log.Fatalf("Failed to read input file %v", err)
	}
	err = yaml.Unmarshal(yamlFile, &config)
	if err != nil {
		log.Fatalf("Failed to create config object %v", err)
	}
	return config
}

func (n *NetworkLauncher) getOrdererAddresses(networkSpec Config) ([]string, []OrdererCert) {
	var orderers []string
	var ordererCerts []OrdererCert
	for i := 0; i < len(networkSpec.OrdererOrganizations); i++ {
		for j := 0; j < networkSpec.OrdererOrganizations[i].NumOrderers; j++ {
			orderers = append(orderers, fmt.Sprintf("orderer%v-%s:7050", j, networkSpec.OrdererOrganizations[i].Name))
			if networkSpec.OrdererConfig.OrdererType == "etcdraft" {
				hostName := fmt.Sprintf("orderer%v-%s", j, networkSpec.OrdererOrganizations[i].Name)
				tlsCertLocation := fmt.Sprintf("%vcrypto-config/ordererOrganizations/%v/orderers/%v.%v/tls/server.crt", networkSpec.ArtifactsLocation, networkSpec.OrdererOrganizations[i].Name, hostName, networkSpec.OrdererOrganizations[i].Name)
				ordererCert := OrdererCert{Host: hostName, TlsCertLocation: tlsCertLocation}
				ordererCerts = append(ordererCerts, ordererCert)
			}
		}
	}
	return orderers, ordererCerts
}

func (n *NetworkLauncher) Iterator(num int) []int{
	var result []int
	for i := 0; i < num; i++ {
		result = append(result,i)
	}
	return result
}

func (n *NetworkLauncher) GenerateCryptoConfig(networkSpec Config) error {

	var NL NetworkLauncher
	ordererHosts := make(map[string][]string)
	peerHosts := make(map[string][]string)
	for i := 0; i < len(networkSpec.OrdererOrganizations); i++ {
		var hosts []string
		for j := 0; j < networkSpec.OrdererOrganizations[i].NumOrderers; j++ {
			hosts = append(hosts, fmt.Sprintf("orderer%v-%s", j, networkSpec.OrdererOrganizations[i].Name))
		}
		ordererHosts[networkSpec.OrdererOrganizations[i].Name] = hosts
	}

	for i := 0; i < len(networkSpec.PeerOrganizations); i++ {
		var hosts []string
		for j := 0; j < networkSpec.PeerOrganizations[i].NumPeers; j++ {
			hosts = append(hosts, fmt.Sprintf("peer%v-%s", j, networkSpec.PeerOrganizations[i].Name))
		}
		peerHosts[networkSpec.PeerOrganizations[i].Name] = hosts
	}

	cryptoConfigInput := CryptoConfig{OrdererOrganizations: networkSpec.OrdererOrganizations, PeerOrganizations: networkSpec.PeerOrganizations, OrdererHosts: ordererHosts, PeerHosts: peerHosts}
	err := NL.GenerateConfigFiles(cryptoConfigInput)
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	return nil
}

func (n *NetworkLauncher) GenerateConfigtx(networkSpec Config) error {

	var NL NetworkLauncher
	ordererAddresses, ordererCerts := NL.getOrdererAddresses(networkSpec)

	configTxInput := ConfigTx{OrdererOrganizations: networkSpec.OrdererOrganizations, PeerOrganizations: networkSpec.PeerOrganizations, OrdererAddresses: ordererAddresses, OrdererConfig: networkSpec.OrdererConfig, OrdererCerts: ordererCerts, ArtifactsLocation: networkSpec.ArtifactsLocation}
	err := NL.GenerateConfigFiles(configTxInput)

	if err != nil {
		return fmt.Errorf("%v", err)
	}
	return nil
}

func (n *NetworkLauncher) GenerateK8sService(networkSpec Config) error {

	var NL NetworkLauncher
	k8sServiceInput := K8sServices{OrdererOrganizations: networkSpec.OrdererOrganizations, PeerOrganizations: networkSpec.PeerOrganizations}
	err := NL.GenerateConfigFiles(k8sServiceInput)

	if err != nil {
		return fmt.Errorf("%v", err)
	}
	return nil
}

func (n *NetworkLauncher) GenerateFabricK8sPods(networkSpec Config) error {

	organizations := make(map[string]interface{})
	organizations["peer"] = networkSpec.PeerOrganizations
	organizations["orderer"] = networkSpec.OrdererOrganizations
	var NL NetworkLauncher
	fabricK8sPodsInput := FabricK8sPods{Organizations: organizations}
	err := NL.GenerateConfigFiles(fabricK8sPodsInput)

	if err != nil {
		return fmt.Errorf("%v", err)
	}
	return nil
}

func (n *NetworkLauncher) GenerateConfigFiles(input interface{}) error {

	var NL NetworkLauncher
	var fileName string
	var action string
	var fileTemplate string

	switch fmt.Sprintf("%T", input) {
	case "main.ConfigTx":
		fileName = "configtx.yaml"
		action = "configtx"
		fileTemplate = templates.DefaultConfigTxTemplate()
	case "main.CryptoConfig":
		fileName = "crypto-config.yaml"
		action = "crypto-config"
		fileTemplate = templates.DefaultCryptoConfigTemplate()
	case "main.K8sServices":
		fileName = "k8s-service.yaml"
		action = "k8s-service"
		fileTemplate = templates.DefaultK8sServiceTemplate()
	case "main.FabricK8sPods":
		fileName = "fabrick8s-pods.yaml"
		action = "k8s-pods"
		fileTemplate = templates.DefaultFabricK8sPodsTemplate()
	}

	currentDir, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}

	config, err := os.Create(filepath.Join(currentDir, "./", fileName))
	if err != nil {
		return fmt.Errorf("Failed to create %v path", action)
	}

	defer config.Close()
	var templateResult *template.Template
	templateResult, err = template.New(action).Funcs(template.FuncMap{"N": NL.Iterator}).Parse(fileTemplate)

	if err != nil {
		return fmt.Errorf("Failed to parse %v template", action)
	}

	err = templateResult.Execute(io.MultiWriter(config), input)
	if err != nil {
		return fmt.Errorf("Failed to create %v.yaml", action)
	}

	return nil
}

func (n *NetworkLauncher) GenerateCryptoCerts(networkSpec Config) error {

	cmd := exec.Command("cryptogen", "generate", "--config=./crypto-config.yaml", fmt.Sprintf("--output=%vcrypto-config", networkSpec.ArtifactsLocation))

	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	fmt.Printf(string(stdoutStderr))
	return nil
}

func (n *NetworkLauncher) GenerateOrdererGenesisBlock() error {
	cmd := exec.Command("configtxgen", "-profile", "testOrgsOrdererGenesis", "-channelID", "ordersystemchannel", "-outputBlock", "./genesis.block")
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	fmt.Printf(string(stdoutStderr))
	return nil
}

func (n *NetworkLauncher) GenerateChannelTransaction(networkSpec Config) error {

	for i := 0; i < networkSpec.NumChannels; i++ {
		cmd := exec.Command("configtxgen", "-profile", "testorgschannel", "-channelCreateTxBaseProfile", "testOrgsOrdererGenesis", "-channelID", fmt.Sprintf("testorgschannel%v", i), "-outputCreateChannelTx", fmt.Sprintf("./testorgschannel%v.tx", i))
		stdoutStderr, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("%v", err)
		}
		fmt.Printf(string(stdoutStderr))
	}
	return nil
}

func (n *NetworkLauncher) ReadArguments() (*string, *string) {

	networkSpecPath := flag.String("i", "", "Network spec input file path")
	kubeConfigPath := flag.String("k", "", "Kube config file path")

	flag.Parse()
	if fmt.Sprintf("%s", *kubeConfigPath) == "" {
		fmt.Println("Kube config file path not provided")
	}
	if fmt.Sprintf("%s", *networkSpecPath) == "" {
		log.Fatalf("Network spec file path not provided")
	}

	return networkSpecPath, kubeConfigPath
}

func main() {
	var NL NetworkLauncher

	networkSpecPath, _ := NL.ReadArguments()
	input := NL.getConf(*networkSpecPath)

	err := NL.GenerateCryptoConfig(input)
	if err != nil {
		log.Fatalf("Failed to create crypto-config.yaml file %v", err)
	}

	err = NL.GenerateCryptoCerts(input)
	if err != nil {
		log.Fatalf("Failed to generate certificates %v", err)
	}

	err = NL.GenerateConfigtx(input)
	if err != nil {
		log.Fatalf("Failed to create configtx.yaml file %v", err)
	}

	err = NL.GenerateOrdererGenesisBlock()
	if err != nil {
		log.Fatalf("Failed to create orderer genesis block %v", err)
	}
	err = NL.GenerateChannelTransaction(input)
	if err != nil {
		log.Fatalf("Failed to create channel transaction %v", err)
	}

	err = NL.GenerateK8sService(input)
	if err != nil {
		log.Fatalf("%v", err)
	}

	err = NL.GenerateFabricK8sPods(input)
	if err != nil {
		log.Fatalf("%v", err)
	}

}
