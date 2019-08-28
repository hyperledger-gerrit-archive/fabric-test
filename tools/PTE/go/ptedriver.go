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
)


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


func doAction(action, inputFilePath string){

	var actions []string
	if action == "all"{
		actions = append(actions, []string{"createChannel", "joinChannel", "installCC", "instantiateCC", "traffic"}...)
	} else{
		actions = append(actions, action)
	}
	for i:=0; i<len(actions); i++{
		switch actions[i] {
		case "createChannel":
			err := CreateChannel(inputFilePath)
			if err != nil {
				log.Fatalf("Failed to create channel; err=%v", err)
			}
		case "joinChannel":
			err := JoinChannel(inputFilePath)
			if err != nil {
				log.Fatalf("Failed to join channel; err=%v", err)
			}
		case "installCC":
			err := InstallCC(inputFilePath)
			if err != nil {
				log.Fatalf("Failed to install chaincode; err=%v", err)
			}
		case "instantiateCC":
			err := InstantiateCC(inputFilePath)
			if err != nil {
				log.Fatalf("Failed to instantiateCC; err=%v", err)
			}
		case "traffic":
			err := SendTraffic(inputFilePath)
			if err != nil {
				log.Fatalf("Failed to send traffic; err=%v", err)
			}
		default:
			log.Fatalf("Incorrect action: (%v). Use creatChannel, joinChannel, installCC, instantiateCC, traffic for action", action)
		}
	}
}

func main(){
	inputFilePath, action := ReadArguments()
    doAction(action, inputFilePath)
}