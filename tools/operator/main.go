package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"

	Client "github.com/hyperledger/fabric-test/tools/operator/client"
	helper "github.com/hyperledger/fabric-test/tools/operator/launcher/helper"
	NL "github.com/hyperledger/fabric-test/tools/operator/launcher/nl"
)

func readArguments() (string, string, string) {

	networkSpecPath := flag.String("i", "", "Network spec input file path")
	kubeConfigPath := flag.String("k", "", "Kube config file path")
	mode := flag.String("m", "", "mode")
	flag.Parse()

	if fmt.Sprintf("%s", *kubeConfigPath) == "" {
		fmt.Println("Kube config file not provided")
	} else if fmt.Sprintf("%s", *networkSpecPath) == "" {
		log.Fatalf("Input file not provided")
	}

	return *networkSpecPath, *kubeConfigPath, *mode
}

func modeAction(mode string, input helper.Config) {

	switch mode {
	case "createChannelTxn":
		configTxnPath := "./launcher/configFiles"
		channels := []string{}
		err := Client.GenerateChannelTransaction(input, channels, configTxnPath)
		if err != nil {
			log.Fatalf("Failed to create channel transaction: err=%v", err)
		}
	case "migrate":
		err := Client.MigrateToRaft(input, kubeconfigPath)
		if err != nil {
			log.Fatalf("Failed to migrate consensus from %v to raft: err=%v", input.Orderer.OrdererType, err)
		}
	default:
		log.Fatalf("Incorrect mode (%v). Use createChannelTxn or migrate for mode", mode)
	}
}

func main() {

	networkSpecPath, _, mode := readArguments()
	contents, _ := ioutil.ReadFile(networkSpecPath)
	contents = append([]byte("#@data/values \n"), contents...)
	inputPath := "templates/input.yaml"
	ioutil.WriteFile(inputPath, contents, 0644)
	Client.CreateConfigPath()
	input := NL.GetConfigData(inputPath)
	modeAction(mode, input)
}
