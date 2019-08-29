package main

import (
	"flag"
	"io/ioutil"

	"github.com/hyperledger/fabric-test/tools/operator/logger"
	"github.com/hyperledger/fabric-test/tools/operator/testclient/helper"
	"github.com/hyperledger/fabric-test/tools/operator/testclient/operations"
	yaml "gopkg.in/yaml.v2"
)

var pteInputFilePath = flag.String("i", "", "Input file for pte (Required)")
var action = flag.String("a", "", "Action to perform")

func validateArguments(pteInputFilePath *string) {

	if *pteInputFilePath == "" {
		logger.CRIT(nil, "Input file not provided")
	}
	if *action == "" {
		*action = "all"
	}
}

//GetInputData -- Read in the input data and parse the objects
func GetInputData(inputFilePath string) (helper.Config, error) {

	var config helper.Config
	yamlFile, err := ioutil.ReadFile(inputFilePath)
	if err != nil {
		logger.ERROR("Failed to read input file")
		return config, err
	}
	err = yaml.Unmarshal(yamlFile, &config)
	if err != nil {
		logger.ERROR("Failed to create config object")
		return config, err
	}
	return config, nil
}

func doAction(action string, config helper.Config) {

	var actions []string
	tls := config.TLS
	switch tls {
	case "true":
		tls = "enabled"
	case "false":
		tls = "disabled"
	case "mutual":
		tls = "clientauth"
	}
	if action == "all" {
		actions = append(actions, []string{"create", "anchorpeer"}...)
	} else {
		actions = append(actions, action)
	}
	for i := 0; i < len(actions); i++ {
		switch actions[i] {
		case "create":
			var create operations.CreateChannelObject
			err := create.CreateChannels(config, tls)
			if err != nil {
				logger.CRIT(err, "Failed to create channels")
			}
		case "anchorpeer":
            var anchorpeer operations.AnchorPeerUpdateObject
            err := anchorpeer.AnchorPeerUpdate(config, tls)
            if err != nil {
                logger.CRIT(err, "Failed to update anchor peer")
            }
		default:
			logger.CRIT(nil, "Incorrect action: ", action, " Use create for action")
		}
    }
}

func main() {

	flag.Parse()
	validateArguments(pteInputFilePath)
	config, err := GetInputData(*pteInputFilePath)
	if err != nil {
		logger.CRIT(err)
	}
	doAction(*action, config)
}
