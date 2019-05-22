package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os/exec"
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

func (n *NetworkLauncher) GenerateConfigurationFiles() error {

	cmd := exec.Command("./ytt-linux-amd64", "-f", "./templates/", "--output", "./configFiles")

	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	fmt.Printf(string(stdoutStderr))
	return nil
}

func (n *NetworkLauncher) GenerateCryptoCerts(networkSpec Config) error {

	cmd := exec.Command("cryptogen", "generate", "--config=./configFiles/crypto-config.yaml", fmt.Sprintf("--output=%vcrypto-config", networkSpec.ArtifactsLocation))

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

	err := NL.GenerateConfigurationFiles()
	if err != nil {
		log.Fatalf("Failed to generate yaml files%v", err)
	}

	err = NL.GenerateCryptoCerts(input)
	if err != nil {
		log.Fatalf("Failed to generate certificates %v", err)
	}

	err = NL.GenerateOrdererGenesisBlock()
	if err != nil {
		log.Fatalf("Failed to create orderer genesis block %v", err)
	}
	
	err = NL.GenerateChannelTransaction(input)
	if err != nil {
		log.Fatalf("Failed to create channel transaction %v", err)
	}
}
