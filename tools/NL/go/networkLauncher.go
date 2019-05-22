package main

import (
	"errors"
	"io"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"text/template"

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

type ConfigTx struct {
	OrdererOrganizations []OrdererOrganizations `yaml:"orderer_organizations,omitempty"`
	PeerOrganizations    []PeerOrganizations    `yaml:"peer_organizations,omitempty"`
	OrdererAddresses     []string               `yaml:"orderer_addresses,omitempty"`
	OrdererConfig        OrdererConfig          `yaml:"orderer,omitempty"`
	OrdererCerts         []OrdererCert          `yaml:"orderer_certs,omitempty"`
	ArtifactsLocation    string                 `yaml:"certs_location,omitempty"`
}

type OrdererCert struct {
	Host            string `yaml:"host"`
	TlsCertLocation string `yaml:"tls_cert_location`
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

func (n *NetworkLauncher) getConf() Config {
	var config Config
	yamlFile, err := ioutil.ReadFile("./../networkspec.yaml")
	if err != nil {
		log.Fatalf("Failed to read input file ", err)
	}
	err = yaml.Unmarshal(yamlFile, &config)
	if err != nil {
		log.Fatalf("Failed to create config object ", err)
	}
	return config
}

func (n *NetworkLauncher) getOrdererAddresses() ([]string, []OrdererCert) {
	input := n.getConf()
	var orderers []string
	var ordererCerts []OrdererCert
	for i := 0; i < len(input.OrdererOrganizations); i++ {
		for j := 0; j < input.OrdererOrganizations[i].NumOrderers; j++ {
			orderers = append(orderers, "orderer"+strconv.Itoa(j)+"-"+input.OrdererOrganizations[i].Name+":7050")
			if input.OrdererConfig.OrdererType == "etcdraft" {
				ordererCerts = append(ordererCerts, OrdererCert{"orderer" + strconv.Itoa(j) + "-" + input.OrdererOrganizations[i].Name, input.ArtifactsLocation + "crypto-config/ordererOrganizations/" + input.OrdererOrganizations[i].Name + "/orderers/orderer" + strconv.Itoa(j) + "-" + input.OrdererOrganizations[i].Name + "." + input.OrdererOrganizations[i].Name + "/tls/server.crt"})
			}
		}
	}
	return orderers, ordererCerts
}

func (n *NetworkLauncher) GenerateConfigTxConfig(configTxInput ConfigTx) error {
	config, err := os.Create(filepath.Join("./../", "configtx.yaml"))
	if err != nil {
		return errors.New("Failed to create configtx path")
	}
	defer config.Close()
	template, err := template.New("configtx").Parse(DefaultConfigTxTemplate())
	if err != nil {
		return errors.New("Failed to parse template")
	}
	err = template.Execute(io.MultiWriter(config), configTxInput)
	if err != nil {
		return errors.New("Failed to create configtx.yaml")
	}
	return nil
}

func main() {
	var NL NetworkLauncher
	input := NL.getConf()

	ordererAddresses, ordererCerts := NL.getOrdererAddresses()
	configTxInput := ConfigTx{input.OrdererOrganizations, input.PeerOrganizations, ordererAddresses, input.OrdererConfig, ordererCerts, input.ArtifactsLocation}

	err := NL.GenerateConfigTxConfig(configTxInput)
	if err != nil {
		log.Fatalf("Failed to generate configtx.yaml ", err)
	}
}
