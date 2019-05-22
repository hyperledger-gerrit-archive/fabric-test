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
	ArtifactsLocation string `yaml:"certs_location,omitempty"`
	NumChannels       int    `yaml:"num_channels,omitempty"`
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
		log.Fatalf("Failed to create services %v", err)
	}
}
