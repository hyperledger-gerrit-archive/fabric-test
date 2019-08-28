package networkspec

import (
	"fmt"
	"io/ioutil"
	"flag"
	"log"
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