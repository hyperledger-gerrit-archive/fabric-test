package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"kanni-test/test/fabric-test/tools/operator/launcher/nl"
	"log"
	
	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/launcher/nl"
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

func doAction(action string, input networkspec.Config) {

	switch action {
	case "createChannelTxn":
		configTxnPath := "./launcher/configFiles"
		channels := []string{}
		err := client.GenerateChannelTransaction(input, channels, configTxnPath)
		if err != nil {
			log.Fatalf("Failed to create channel transaction: err=%v", err)
		}
	case "migrate":
		err := client.MigrateToRaft(input, kubeconfigPath)
		if err != nil {
			log.Fatalf("Failed to migrate consensus from %v to raft: err=%v", input.Orderer.OrdererType, err)
		}
	default:
		log.Fatalf("Incorrect mode (%v). Use createChannelTxn or migrate for mode", mode)
	}
}

func main() {

	networkSpecPath, _, action := readArguments()
	contents, _ := ioutil.ReadFile(networkSpecPath)
	contents = append([]byte("#@data/values \n"), contents...)
	inputPath := "templates/input.yaml"
	ioutil.WriteFile(inputPath, contents, 0644)
	client.CreateConfigPath()
	input := nl.GetConfigData(inputPath)
	doAction(action, input)
}
