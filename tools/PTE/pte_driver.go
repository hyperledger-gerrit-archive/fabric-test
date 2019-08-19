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

	yaml "gopkg.in/yaml.v2"
)

//ReadArguments -- To read in the input arguments
func ReadArguments() (string, string) {

	inputFilePath := flag.String("i", "", "Network configuration file path (required)")
	action := flag.String("a", "", "Set action (Available options creatChannel, joinChannel, installCC, instantiateCC, traffic)")
	flag.Parse()
	if fmt.Sprintf("%s", *inputFilePath) == "" {
		log.Fatalf("Input file not provided")
	}
	if *action == "" {
		*action = "all"
		fmt.Println("Action not provided, proceeding with all the actions")
	}
	return *inputFilePath, *action
}

//GetInputData -- Read in the input data and parse the objects
func GetInputData(inputFilePath string) (Config, error) {

	var config Config
	yamlFile, err := ioutil.ReadFile(inputFilePath)
	if err != nil {
		return config, fmt.Errorf("Failed to read input file; err = %v", err)
	}
	err = yaml.Unmarshal(yamlFile, &config)
	if err != nil {
		log.Fatalf("Failed to create config object; err = %v", err)
	}
	return config, nil
}

//CreateChannels -- To craete channel
func CreateChannels(inputFilePath string) error {

	config, err := GetInputData(inputFilePath)
	if err != nil {
		return err
	}
	orgs := []string{"org1"}
	_, createChannelObject, err := createOpereationObject(config, "testorgschannel1", "create", orgs)
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	err = execCommand("node", "node/pte-main.js", createChannelObject)
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	return nil
}

//JoinChannel -- To join channel
func JoinChannel(inputFilePath string) error {

	config, err := GetInputData(inputFilePath)
	if err != nil {
		return err
	}
	_, joinChannelObject, err := createOpereationObject(config, "testorgschannel1", "join", []string{"org1"})
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	err = execCommand("node", "node/pte-main.js", joinChannelObject)
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	return nil
}

//InstallCC -- To install chaincode
func InstallCC(inputFilePath string) error {

	config, err := GetInputData(inputFilePath)
	if err != nil {
		return err
	}
	_, installCCObject, err := createOpereationObject(config, "testorgschannel1", "install", []string{"org1"})
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	err = execCommand("node", "node/pte-main.js", installCCObject)
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	return nil
}

//InstantiateCC -- To instantiate chaincode
func InstantiateCC(inputFilePath string) error {

	config, err := GetInputData(inputFilePath)
	if err != nil {
		return err
	}
	_, instantiateCCObject, err := createOpereationObject(config, "testorgschannel1", "instantiate", []string{"org1"})
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	err = execCommand("node", "node/pte-main.js", instantiateCCObject)
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	return nil
}

//SendTraffic -- To send traffic
func SendTraffic(inputFilePath string) error {

	_, err := GetInputData(inputFilePath)
	if err != nil {
		return err
	}

	return nil
}

func createOpereationObject(input Config, channelName, action string, orgs []string) (Operations, string, error) {

	var operation Operations
	operation.TransType = "Channel"
	operation.ChaincodeID = input.Chaincode.ChaincodeID
	operation.ChaincodeVer = input.Chaincode.ChaincodeVer
	if input.TLS == "true" {
		operation.TLS = "enabled"
	} else if input.TLS == "false" {
		operation.TLS = "disabled"
	} else {
		operation.TLS = input.TLS
	}
	operation.ChannelOpt.Name = channelName
	operation.ChannelOpt.ChannelTX = filepath.Join(input.ArtifactsLocation, fmt.Sprintf("channel-artifacts/%v.tx", channelName))
	operation.ChannelOpt.Action = action
	operation.ChannelOpt.OrgName = append(operation.ChannelOpt.OrgName, orgs...)
	operation.ConnProfilePath = filepath.Join(input.ArtifactsLocation, "connection-profile")
	operation.Deploy.ChaincodePath = input.Chaincode.ChaincodePath
	operation.Deploy.MetadataPath = input.Chaincode.MetadataPath
	operation.Deploy.Language = input.Chaincode.Language
	operation.Deploy.Fcn = input.Chaincode.Fcn
	operation.Deploy.Args = append(operation.Deploy.Args, input.Chaincode.Args...)
	object, err := json.MarshalIndent(operation, "", " ")
	if err != nil {
		return operation, string(object), fmt.Errorf("Failed to create operation object; err:%v", err)
	}
	return operation, string(object), nil
}

func execCommand(name string, args ...string) error {

	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("Failed to execute the command; err: %v", cmd.Stderr)
	}
	return nil
}
