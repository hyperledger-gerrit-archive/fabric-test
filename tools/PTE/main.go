package main

import (
    "log"
)

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