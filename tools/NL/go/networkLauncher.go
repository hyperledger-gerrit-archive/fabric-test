package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

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
type CA struct {
	Pem        string `json:"pem"`
	PrivateKey string `json:"private_key"`
}
type TlsCa struct {
	Pem        string `json:"pem"`
	PrivateKey string `json:"private_key"`
}
type Component struct {
	Msp   MSP   `json:"msp"`
	Tls   TLS   `json:"tls"`
	Ca    CA    `json:"ca"`
	Tlsca TlsCa `json:"tlsca"`
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

	cmd := exec.Command("uname", "-s")
	stdoutStderr, err := cmd.CombinedOutput()
	osType := fmt.Sprintf(strings.TrimSpace(strings.ToLower(string(stdoutStderr))))
	cmd = exec.Command(fmt.Sprintf("./ytt-%v-amd64", osType), "-f", "./templates/", "--output", "./configFiles")
	stdoutStderr, err = cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	fmt.Printf(string(stdoutStderr))
	return nil
}

func (n *NetworkLauncher) GenerateCryptoCerts(networkSpec Config) error {

	configPath := filepath.Join(networkSpec.ArtifactsLocation, "crypto-config")
	cmd := exec.Command("cryptogen", "generate", "--config=./configFiles/crypto-config.yaml", fmt.Sprintf("--output=%v", configPath))
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	fmt.Printf(string(stdoutStderr))
	return nil
}

func (n *NetworkLauncher) CreateMspJson(networkSpec Config, path string, caPath string, componentName string, kubeConfigPath string) error {

	var msp MSP
	var tls TLS
	var ca CA
	var tlsCa TlsCa
	var component Component
	var tlsArr []string
	if strings.HasPrefix(componentName, "orderer") || strings.HasPrefix(componentName, "peer") {
		files, err := ioutil.ReadDir(path)
		if err != nil {
			log.Fatal(err)
		}
		dir := path
		for _, f := range files {
			if f.Name() == "msp" {
				mspDir, _ := ioutil.ReadDir(fmt.Sprintf("%v/msp", dir))
				var mspArr []string
				for _, sf := range mspDir {
					mspSubDir, _ := ioutil.ReadDir(fmt.Sprintf("%v/msp/%v", dir, sf.Name()))
					for _, j := range mspSubDir {
						data, _ := ioutil.ReadFile(fmt.Sprintf("%v/msp/%v/%v", dir, sf.Name(), j.Name()))
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
	}

	files, err := ioutil.ReadDir(caPath)
	if err != nil {
		log.Fatal(err)
	}

	for _, f := range files {
		dir := fmt.Sprintf("%v/%v", caPath, f.Name())
		if f.Name() == "ca" {
			caDir, _ := ioutil.ReadDir(fmt.Sprintf("%v/", dir))
			var caCerts []string
			for _, file := range caDir {
				data, _ := ioutil.ReadFile(fmt.Sprintf("%v/%v", dir, file.Name()))
				caCerts = append(caCerts, string(data))
			}
			ca.PrivateKey = caCerts[0]
			ca.Pem = caCerts[1]
		} else if f.Name() == "tlsca" {
			tlsCaDir, _ := ioutil.ReadDir(fmt.Sprintf("%v/", dir))
			var tlsCaCerts []string
			for _, file := range tlsCaDir {
				data, _ := ioutil.ReadFile(fmt.Sprintf("%v/%v", dir, file.Name()))
				tlsCaCerts = append(tlsCaCerts, string(data))
			}
			tlsCa.PrivateKey = tlsCaCerts[0]
			tlsCa.Pem = tlsCaCerts[1]
		}
	}

	component.Ca = ca
	component.Tlsca = tlsCa
	b, _ := json.MarshalIndent(component, "", "  ")
	_ = ioutil.WriteFile(fmt.Sprintf("./configFiles/%v.json", componentName), b, 0644)
	cmd := exec.Command("kubectl", fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "create", "secret", "generic", fmt.Sprintf("%v", componentName), fmt.Sprintf("--from-file=./configFiles/%v.json", componentName))
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	fmt.Printf(string(stdoutStderr))
	return nil
}

func (n *NetworkLauncher) CreateMspSecret(networkSpec Config, kubeConfigPath string) error {

	var NL NetworkLauncher
	for i := 0; i < len(networkSpec.OrdererOrganizations); i++ {
		for j := 0; j < networkSpec.OrdererOrganizations[i].NumOrderers; j++ {
			ordererName := fmt.Sprintf("orderer%s-%s", fmt.Sprintf("%v", j), networkSpec.OrdererOrganizations[i].Name)
			caPath := networkSpec.ArtifactsLocation + "crypto-config/ordererOrganizations/" + networkSpec.OrdererOrganizations[i].Name
			path := networkSpec.ArtifactsLocation + "crypto-config/ordererOrganizations/" + networkSpec.OrdererOrganizations[i].Name + "/orderers/" + ordererName + "." + networkSpec.OrdererOrganizations[i].Name
			_ = NL.CreateMspJson(networkSpec, path, caPath, ordererName, kubeConfigPath)
		}
		for j := 0; j < networkSpec.OrdererOrganizations[i].NumCa; j++ {
			caName := fmt.Sprintf("ca%s-%s", fmt.Sprintf("%v", j), networkSpec.OrdererOrganizations[i].Name)
			caPath := networkSpec.ArtifactsLocation + "crypto-config/ordererOrganizations/" + networkSpec.OrdererOrganizations[i].Name
			_ = NL.CreateMspJson(networkSpec, "", caPath, caName, kubeConfigPath)
		}
	}

	for i := 0; i < len(networkSpec.PeerOrganizations); i++ {
		for j := 0; j < networkSpec.PeerOrganizations[i].NumPeers; j++ {
			peerName := fmt.Sprintf("peer%s-%s", fmt.Sprintf("%v", j), networkSpec.PeerOrganizations[i].Name)
			path := networkSpec.ArtifactsLocation + "crypto-config/peerOrganizations/" + networkSpec.PeerOrganizations[i].Name + "/peers/" + peerName + "." + networkSpec.PeerOrganizations[i].Name
			caPath := networkSpec.ArtifactsLocation + "crypto-config/peerOrganizations/" + networkSpec.PeerOrganizations[i].Name
			_ = NL.CreateMspJson(networkSpec, path, caPath, peerName, kubeConfigPath)
		}
		for j := 0; j < networkSpec.PeerOrganizations[i].NumCa; j++ {
			caName := fmt.Sprintf("ca%s-%s", fmt.Sprintf("%v", j), networkSpec.PeerOrganizations[i].Name)
			caPath := networkSpec.ArtifactsLocation + "crypto-config/peerOrganizations/" + networkSpec.PeerOrganizations[i].Name
			_ = NL.CreateMspJson(networkSpec, "", caPath, caName, kubeConfigPath)
		}
	}
	return nil
}

func (n *NetworkLauncher) GenerateOrdererGenesisBlock(networkSpec Config, kubeConfigPath string) error {

	path := filepath.Join(networkSpec.ArtifactsLocation, "channel-artifacts")
	err := os.Mkdir(path, 0755)

	cmd := exec.Command("configtxgen", "-profile", "testOrgsOrdererGenesis", "-channelID", "ordersystemchannel", "-outputBlock", fmt.Sprintf("%v/genesis.block", path), "-configPath=./configFiles/")
	stdoutStderr, err := cmd.CombinedOutput()

	if err != nil {
		return fmt.Errorf("%v", err)
	}
	fmt.Printf(string(stdoutStderr))
	cmd = exec.Command("kubectl", fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "create", "secret", "generic", "genesisblock", fmt.Sprintf("--from-file=%v/genesis.block", path))
	stdoutStderr, err = cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	fmt.Printf(string(stdoutStderr))
	return nil
}

func (n *NetworkLauncher) GenerateChannelTransaction(networkSpec Config) error {

	path := filepath.Join(networkSpec.ArtifactsLocation, "channel-artifacts")
	_ = os.Mkdir(path, 0755)

	for i := 0; i < networkSpec.NumChannels; i++ {
		cmd := exec.Command("configtxgen", "-profile", "testorgschannel", "-channelCreateTxBaseProfile", "testOrgsOrdererGenesis", "-channelID", fmt.Sprintf("testorgschannel%v", i), "-outputCreateChannelTx", fmt.Sprintf("%v/testorgschannel%v.tx", path, i), "-configPath=./configFiles/")
		stdoutStderr, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("%v", err)
		}
		fmt.Printf(string(stdoutStderr))
	}
	return nil
}

func (n *NetworkLauncher) CreateCertsParserConfigMap(kubeConfigPath string) error {

	cmd := exec.Command("kubectl", "--kubeconfig="+kubeConfigPath, "create", "configmap", "certsparser", "--from-file=./scripts/certs-parser.sh")
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

func init() {

	currentDir, err := os.Getwd()
	if err != nil {
		log.Fatalf("%v", err)
	}
	cmd := exec.Command("uname", "-s")
	stdoutStderr, err := cmd.CombinedOutput()

	osType := fmt.Sprintf(strings.TrimSpace(strings.ToLower(string(stdoutStderr))))
	path := filepath.Join(currentDir, fmt.Sprintf("ytt-%v-amd64", osType))

	if _, err = os.Stat(path); os.IsNotExist(err) {
		cmd := exec.Command("wget", fmt.Sprintf("https://github.com/k14s/ytt/releases/download/v0.11.0/ytt-%v-amd64", osType))
		_, err := cmd.CombinedOutput()
		if err != nil {
			log.Fatalf("%v", err)
		}
		cmd = exec.Command("chmod", "+x", fmt.Sprintf("ytt-%v-amd64", osType))
		_, err = cmd.CombinedOutput()
		if err != nil {
			log.Fatalf("%v", err)
		}
	}
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
		log.Fatalf("Failed to create secret %v", err)
	}

	err = NL.GenerateOrdererGenesisBlock(input, *kubeConfigPath)
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