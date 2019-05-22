package main

import (
	"encoding/json"
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
	ArtifactsLocation    string                 `yaml:"certs_location,omitempty"`
	OrdererOrganizations []OrdererOrganizations `yaml:"orderer_organizations,omitempty"`
	PeerOrganizations    []PeerOrganizations    `yaml:"peer_organizations,omitempty"`
	NumChannels          int                    `yaml:"num_channels,omitempty"`
}

// OrdererOrganizations struct
type OrdererOrganizations struct {
	Name        string `yaml:"name,omitempty"`
	MspID       string `yaml:"msp_id,omitempty"`
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
	MspID    string `yaml:"msp_id,omitempty"`
	NumPeers int    `yaml:"num_peers,omitempty"`
	NumCa    int    `yaml:"num_ca,omitempty"`
}

type MSP struct {
	AdminCerts struct {
		AdminPem string `json:"admin_pem"`
	} `json:"admin_certs"`
	CACerts struct {
		CaPem string `json:"ca_pem"`
	} `json:"ca_certs"`
	TlsCaCerts struct {
		TlsPem string `json:"tls_pem"`
	} `json:"tls_ca"`
	SignCerts struct {
		OrdererPem string `json:"pem"`
	} `json:"sign_certs"`
	Keystore struct {
		PrivateKey string `json:"private_key"`
	} `json:"key_store"`
}
type TLS struct {
	CaCert     string `json:"ca_cert"`
	ServerCert string `json:"server_cert"`
	ServerKey  string `json:"server_key"`
}
type Component struct {
	Msp MSP `json:"msp"`
	Tls TLS `json:"tls"`
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

func (n *NetworkLauncher) CreateMspJson(networkSpec Config, path string, componentName string, kubeConfigPath string) error {

	var msp MSP
	var tls TLS
	var component Component
	var tlsArr []string
	files, err := ioutil.ReadDir(path)
	if err != nil {
		log.Fatal(err)
	}
	dir := path
	for _, f := range files {
		if f.Name() == "msp" {
			mspDir, _ := ioutil.ReadDir(fmt.Sprintf("%v/msp",dir))
			var mspArr []string
			for _, sf := range mspDir {
				mspSubDir, _ := ioutil.ReadDir(fmt.Sprintf("%v/msp/%v",dir, sf.Name()))
				for _, j := range mspSubDir {
					data, _ := ioutil.ReadFile(fmt.Sprintf("%v/msp/%v/%v",dir, sf.Name(), j.Name()))
					mspArr = append(mspArr, string(data))
				}
			}
			msp.AdminCerts.AdminPem = mspArr[0]
			msp.CACerts.CaPem = mspArr[1]
			msp.Keystore.PrivateKey = mspArr[2]
			msp.SignCerts.OrdererPem = mspArr[3]
			msp.TlsCaCerts.TlsPem = mspArr[4]
		} else {
			tlsDir, _ := ioutil.ReadDir(fmt.Sprintf("%v/tls", dir))
			for _, sf := range tlsDir {
				data, _ := ioutil.ReadFile(fmt.Sprintf("%v/tls/%v", dir, sf.Name()))
				tlsArr = append(tlsArr, string(data))
			}
			tls.CaCert = tlsArr[0]
			tls.ServerCert = tlsArr[1]
			tls.ServerKey = tlsArr[2]
		}
	}
	component.Msp = msp
	component.Tls = tls
	b, _ := json.MarshalIndent(component, "", "  ")
	_ = ioutil.WriteFile(fmt.Sprintf("./configFiles/%v.json",componentName), b, 0644)
	cmd := exec.Command("kubectl", fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "create", "secret", "generic", fmt.Sprintf("%v", componentName), fmt.Sprintf("--from-file=./configFiles/%v.json", componentName))
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	fmt.Printf(string(stdoutStderr))
	//kubectl create secret generic db-user-pass --from-file=./username.txt
	return nil
}

func (n *NetworkLauncher) CreateMspSecret(networkSpec Config, kubeConfigPath string) error {
	var NL NetworkLauncher

	for i := 0; i < len(networkSpec.OrdererOrganizations); i++ {
		for j := 0; j < networkSpec.OrdererOrganizations[i].NumOrderers; j++ {
			ordererName := fmt.Sprintf("orderer%s-%s", fmt.Sprintf("%v", j), networkSpec.OrdererOrganizations[i].Name)
			path := networkSpec.ArtifactsLocation + "crypto-config/ordererOrganizations/" + networkSpec.OrdererOrganizations[i].Name + "/orderers/" + ordererName + "." + networkSpec.OrdererOrganizations[i].Name
			_ = NL.CreateMspJson(networkSpec, path, ordererName, kubeConfigPath)
		}
	}

	for i := 0; i < len(networkSpec.PeerOrganizations); i++ {
		for j := 0; j < networkSpec.PeerOrganizations[i].NumPeers; j++ {
			peerName := fmt.Sprintf("peer%s-%s", fmt.Sprintf("%v", j), networkSpec.PeerOrganizations[i].Name)
			path := networkSpec.ArtifactsLocation + "crypto-config/peerOrganizations/" + networkSpec.PeerOrganizations[i].Name + "/peers/" + peerName + "." + networkSpec.PeerOrganizations[i].Name
			_ = NL.CreateMspJson(networkSpec, path, peerName, kubeConfigPath)
		}
	}
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

func (n *NetworkLauncher) CreateCertsParserConfigMap(kubeConfigPath string) error {

	cmd := exec.Command("kubectl", "--kubeconfig="+kubeConfigPath, "create", "configmap", "--from-file==./scripts/certs-parser.sh")
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	fmt.Printf(string(stdoutStderr))
	return nil
}

func (n *NetworkLauncher) CreateServices(kubeConfigPath string) error {

	cmd := exec.Command("kubectl", "--kubeconfig="+kubeConfigPath, "apply", "-f", "./configFiles/k8s-service.yaml")
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	fmt.Printf(string(stdoutStderr))
	return nil
}

func (n *NetworkLauncher) DeployFabric(kubeConfigPath string) error {

	cmd := exec.Command("kubectl", "--kubeconfig="+kubeConfigPath, "apply", "-f", "./configFiles/fabric-k8s-pods.yaml")
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	fmt.Printf(string(stdoutStderr))
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

	networkSpecPath, kubeConfigPath := NL.ReadArguments()
	input := NL.getConf(*networkSpecPath)

	err := NL.GenerateConfigurationFiles()
	if err != nil {
		log.Fatalf("Failed to generate yaml files%v", err)
	}

	err = NL.GenerateCryptoCerts(input)
	if err != nil {
		log.Fatalf("Failed to generate certificates %v", err)
	}

	err = NL.CreateMspSecret(input, *kubeConfigPath)
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

	err = NL.CreateCertsParserConfigMap(*kubeConfigPath)
	if err != nil {
		log.Fatalf("Failed to create cert parser configmap %v", err)
	}

	err = NL.CreateServices(*kubeConfigPath)
	if err != nil {
		log.Fatalf("Failed to create services %v", err)
	}

	err = NL.DeployFabric(*kubeConfigPath)
	if err != nil {
		log.Fatalf("Failed to deploy fabric %v", err)
	}
}
