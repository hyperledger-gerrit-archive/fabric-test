package client

import (
	"os"

	"github.com/hyperledger/fabric-test/tools/operator/paths"
	"github.com/hyperledger/fabric-test/tools/operator/ytt"
)

//CreateConfigTxYaml - to check if the configtx.yaml exists and generates one if not exists
func CreateConfigTxYaml() error {

	var err error
	configFilesDir := paths.ConfigFilesDir()
	configtxTemplatePath := paths.TemplateFilePath("configtx")
	inputFilePath := paths.TemplateFilePath("input")
	configtxPath := paths.ConfigFilePath("configtx")
	if _, err = os.Stat(configtxPath); !os.IsNotExist(err) {
		return nil
	}
	ytt := ytt.YTTPath()
	input := []string{configtxTemplatePath}
	yttObject := ytt.YTT{InputPath: inputFilePath, OutputPath: configFilesDir}
	if _, err = os.Stat(ytt); os.IsNotExist(err) {
		err = paths.DownloadYtt()
		if err != nil {
			return err
		}
	}
	_, err = ExecuteCommand(ytt, yttObject.Args(input), true)
	if err != nil {
		return err
	}
	return nil
}
