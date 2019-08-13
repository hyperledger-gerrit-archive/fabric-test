package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	// "strings"

	"github.com/hyperledger/fabric-test/tools/operator/launcher/nl"
	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
)

func readArguments() (string, string, string, string) {

	networkSpecPath := flag.String("i", "", "Network spec input file path (required)")
	kubeConfigPath := flag.String("k", "", "Kube config file path (optional)")
	action := flag.String("a", "", "Set action (Available options createChannelTxn, migrate, healthz)")
	component := flag.String("c", "", "Component name of a peer or orderer (Use with healthcheck action; omit to check all components)")

	flag.Parse()

	if fmt.Sprintf("%s", *kubeConfigPath) == "" {
		fmt.Println("Kube config file not provided")
	} else if fmt.Sprintf("%s", *networkSpecPath) == "" {
		log.Fatalf("Input file not provided")
	}

	return *networkSpecPath, *kubeConfigPath, *action, *component
}

func doAction(action, kubeConfigPath, componentName string, input networkspec.Config) {

	switch action {
	case "createChannelTxn":
		configTxnPath := "./configFiles"
		channels := []string{}
		err := client.GenerateChannelTransaction(input, channels, configTxnPath)
		if err != nil {
			log.Fatalf("Failed to create channel transaction: err=%v", err)
		}
	case "migrate":
		err := client.MigrateToRaft(input, kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to migrate consensus from %v to raft: err=%v", input.Orderer.OrdererType, err)
		}
	case "healthz":
		err := client.CheckComponentsHealth(componentName, kubeConfigPath, input)
		if err != nil {
			log.Fatalf("Failed to get the health for %v: err=%v", componentName, err)
		}
	default:
		log.Fatalf("Incorrect mode (%v). Use createChannelTxn or migrate for mode", action)
	}
}

func main() {

	networkSpecPath, kubeConfigPath, action, componentName := readArguments()
	contents, _ := ioutil.ReadFile(networkSpecPath)
	contents = append([]byte("#@data/values \n"), contents...)
	inputPath := "templates/input.yaml"
	ioutil.WriteFile(inputPath, contents, 0644)
	client.CreateConfigPath()
	input := nl.GetConfigData(inputPath)
	doAction(action, kubeConfigPath, componentName, input)
}