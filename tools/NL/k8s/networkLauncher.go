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

type Config struct {
	ArtifactsLocation    string                 `yaml:"certs_location,omitempty"`
	OrdererOrganizations []OrdererOrganizations `yaml:"orderer_organizations,omitempty"`
	PeerOrganizations    []PeerOrganizations    `yaml:"peer_organizations,omitempty"`
	NumChannels          int                    `yaml:"num_channels,omitempty"`
}

type OrdererOrganizations struct {
	Name        string `yaml:"name,omitempty"`
	MspID       string `yaml:"msp_id,omitempty"`
	NumOrderers int    `yaml:"num_orderers,omitempty"`
	NumCa       int    `yaml:"num_ca,omitempty"`
}

type KafkaConfig struct {
	NumKafka             int `yaml:"num_kafka,omitempty"`
	NumKafkaReplications int `yaml:"num_kafka_replications,omitempty"`
	NumZookeepers        int `yaml:"num_zookeepers,omitempty"`
}

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

func (NL *NetworkLauncher) getConf(networkSpecPath string) Config {

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

func (NL *NetworkLauncher) GenerateConfigurationFiles() error {

	cmd := exec.Command("uname", "-s")
	stdoutStderr, err := cmd.CombinedOutput()
	osType := fmt.Sprintf(strings.TrimSpace(strings.ToLower(string(stdoutStderr))))

	err = NL.ExecuteCommand(fmt.Sprintf("./ytt-%v-amd64", osType), []string{"-f", "./templates/", "--output", "./configFiles"})
	if err != nil {
		return err
	}
	return nil
}

func (NL *NetworkLauncher) GenerateCryptoCerts(networkSpec Config) error {

	configPath := filepath.Join(networkSpec.ArtifactsLocation, "crypto-config")
	err := NL.ExecuteCommand("cryptogen", []string{"generate", "--config=./configFiles/crypto-config.yaml", fmt.Sprintf("--output=%v", configPath)})
	if err != nil {
		return err
	}
	return nil
}

func (NL *NetworkLauncher) CreateMspJson(networkSpec Config, path string, caPath string, componentName string, kubeConfigPath string) error {

	var msp MSP
	var tls TLS
	var ca CA
	var tlsCa TlsCa
	var component Component
	var tlsArr []string
	if strings.HasPrefix(componentName, "orderer") || strings.HasPrefix(componentName, "peer") {
		files, err := ioutil.ReadDir(path)
		if err != nil {
			return err
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
		return err
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

	err = NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "create", "secret", "generic", fmt.Sprintf("%v", componentName), fmt.Sprintf("--from-file=./configFiles/%v.json", componentName)})
	if err != nil {
		return err
	}

	return nil
}

func (NL *NetworkLauncher) CreateMspSecret(networkSpec Config, kubeConfigPath string) error {

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

func (NL *NetworkLauncher) GenerateOrdererGenesisBlock(networkSpec Config, kubeConfigPath string) error {

	path := filepath.Join(networkSpec.ArtifactsLocation, "channel-artifacts")
	_ = os.Mkdir(path, 0755)

	err := NL.ExecuteCommand("configtxgen", []string{"-profile", "testOrgsOrdererGenesis", "-channelID", "orderersystemchannel", "-outputBlock", fmt.Sprintf("%v/genesis.block", path), "-configPath=./configFiles/"})
	if err != nil {
		return err
	}

	err = NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "create", "secret", "generic", "genesisblock", fmt.Sprintf("--from-file=%v/genesis.block", path)})
	if err != nil {
		return err
	}

	return nil
}

func (NL *NetworkLauncher) GenerateChannelTransaction(networkSpec Config) error {

	path := filepath.Join(networkSpec.ArtifactsLocation, "channel-artifacts")
	_ = os.Mkdir(path, 0755)

	for i := 0; i < networkSpec.NumChannels; i++ {
		err := NL.ExecuteCommand("configtxgen", []string{"-profile", "testorgschannel", "-channelCreateTxBaseProfile", "testOrgsOrdererGenesis", "-channelID", fmt.Sprintf("testorgschannel%v", i), "-outputCreateChannelTx", fmt.Sprintf("%v/testorgschannel%v.tx", path, i), "-configPath=./configFiles/"})
		if err != nil {
			return err
		}
	}
	return nil
}

func (NL *NetworkLauncher) CreateCertsParserConfigMap(kubeConfigPath string) error {

	err := NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "create", "configmap", "certsparser", "--from-file=./scripts/certs-parser.sh"})
	if err != nil {
		return err
	}
	return nil
}

func (NL *NetworkLauncher) CreatePvcs(kubeConfigPath string) error {

	err := NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "apply", "-f", "./configFiles/fabric-k8s-pods.yaml"})
	if err != nil {
		return err
	}
	return nil
}

func (NL *NetworkLauncher) CreateServices(kubeConfigPath string) error {

	err := NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "apply", "-f", "./configFiles/k8s-service.yaml"})
	if err != nil {
		return err
	}
	return nil
}

func (NL *NetworkLauncher) DeployFabric(kubeConfigPath string) error {

	err := NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "apply", "-f", "./configFiles/fabric-k8s-pods.yaml"})
	if err != nil {
		return err
	}
	return nil
}

func (NL *NetworkLauncher) ExecuteCommand(name string, args []string) error {

	stdoutStderr, err := exec.Command(name, args...).CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v", string(stdoutStderr))
	}
	fmt.Printf(string(stdoutStderr))
	return nil
}

func (NL *NetworkLauncher) NetworkCleanUp(networkSpec Config, kubeConfigPath string) error {

	for i := 0; i < len(networkSpec.OrdererOrganizations); i++ {
		for j := 0; j < networkSpec.OrdererOrganizations[i].NumOrderers; j++ {
			ordererName := fmt.Sprintf("orderer%v-%v", j, networkSpec.OrdererOrganizations[i].Name)
			err := NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "delete", "secrets", ordererName})
			if err != nil {
				fmt.Println(err.Error())
			}
		}
		for j := 0; j < networkSpec.OrdererOrganizations[i].NumCa; j++ {
			caName := fmt.Sprintf("ca%v-%v", j, networkSpec.OrdererOrganizations[i].Name)
			err := NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "delete", "secrets", caName})
			if err != nil {
				fmt.Println(err.Error())
			}
		}
	}

	for i := 0; i < len(networkSpec.PeerOrganizations); i++ {
		for j := 0; j < networkSpec.PeerOrganizations[i].NumPeers; j++ {
			peerName := fmt.Sprintf("peer%v-%v", j, networkSpec.PeerOrganizations[i].Name)
			err := NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "delete", "secrets", peerName})
			if err != nil {
				fmt.Println(err.Error())
			}
		}
		for j := 0; j < networkSpec.PeerOrganizations[i].NumCa; j++ {
			caName := fmt.Sprintf("ca%v-%v", j, networkSpec.PeerOrganizations[i].Name)
			err := NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "delete", "secrets", caName})
			if err != nil {
				fmt.Println(err.Error())
			}
		}
	}
	err := NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "delete", "secrets", "genesisblock"})
	err = NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "delete", "-f", "./configFiles/fabric-k8s-pods.yaml"})
	err = NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "delete", "-f", "./configFiles/k8s-service.yaml"})
	err = NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "delete", "-f", "./configFiles/fabric-pvc.yaml"})
	err = NL.ExecuteCommand("kubectl", []string{fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "delete", "configmaps", "certsparser"})
	if err != nil {
		return fmt.Errorf("%v", err)
	}

	currentDir, err := os.Getwd()
	if err != nil {
		err := fmt.Errorf("%v", err)
		fmt.Println(err.Error())
	}
	path := filepath.Join(currentDir, "configFiles")
	err = os.RemoveAll(path)
	path = filepath.Join(currentDir, "templates/networkspec.yaml")
	err = os.RemoveAll(path)
	path = filepath.Join(currentDir, "../../../fabric/internal/cryptogen/channel-artifacts")
	err = os.RemoveAll(path)
	path = filepath.Join(currentDir, "../../../fabric/internal/cryptogen/crypto-config")
	err = os.RemoveAll(path)
	if err != nil {
		return err
	}
	return nil
}

func (NL *NetworkLauncher) ReadArguments() (*string, *string, string) {

	networkSpecPath := flag.String("i", "", "Network spec input file path")
	kubeConfigPath := flag.String("k", "", "Kube config file path")
	mode := flag.String("m", "", "Set mode(up or down)")
	flag.Parse()
	if fmt.Sprintf("%s", *mode) != "down" {
		*mode = "up"
		fmt.Println("mode is set to up")
	}

	if fmt.Sprintf("%s", *kubeConfigPath) == "" || fmt.Sprintf("%s", *networkSpecPath) == "" {
		log.Fatalf("Input file or kube config file not provided")
	}

	return networkSpecPath, kubeConfigPath, fmt.Sprintf("%s", *mode)
}

func init() {
	var NL NetworkLauncher
	currentDir, err := os.Getwd()
	if err != nil {
		log.Fatalf("%v", err)
	}
	cmd := exec.Command("uname", "-s")
	stdoutStderr, err := cmd.CombinedOutput()

	osType := fmt.Sprintf(strings.TrimSpace(strings.ToLower(string(stdoutStderr))))
	path := filepath.Join(currentDir, fmt.Sprintf("ytt-%v-amd64", osType))

	if _, err = os.Stat(path); os.IsNotExist(err) {

		err = NL.ExecuteCommand("wget", []string{fmt.Sprintf("https://github.com/k14s/ytt/releases/download/v0.11.0/ytt-%v-amd64", osType)})
		if err != nil {
			log.Fatalf("%v", err)
		}

		err = NL.ExecuteCommand("chmod", []string{"+x", fmt.Sprintf("ytt-%v-amd64", osType)})
		if err != nil {
			log.Fatalf("%v", err)
		}
	}
}

func main() {
	var NL NetworkLauncher

	networkSpecPath, kubeConfigPath, mode := NL.ReadArguments()
	inputPath := fmt.Sprintf("%s", *networkSpecPath)
	contents, _ := ioutil.ReadFile(inputPath)

	contents = append([]byte("#@data/values \n"), contents...)
	currentDir, err := os.Getwd()
	if err != nil {
		err := fmt.Errorf("%v", err)
		fmt.Println(err.Error())
	}

	ioutil.WriteFile(filepath.Join(currentDir, "templates/networkspec.yaml"), contents, 0644)
	inputPath = fmt.Sprintf("%v", filepath.Join(currentDir, "templates/networkspec.yaml"))
	input := NL.getConf(inputPath)

	if mode == "up" {

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

		err = NL.CreatePvcs(*kubeConfigPath)
		if err != nil {
			log.Printf("Failed to create pvcs %v", err)
		}

		err = NL.CreateServices(*kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to create services %v", err)
		}

		err = NL.DeployFabric(*kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to deploy fabric %v", err)
		}

	} else {
		err := NL.NetworkCleanUp(input, *kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to clean up the network: %v", err)
		}
	}
}