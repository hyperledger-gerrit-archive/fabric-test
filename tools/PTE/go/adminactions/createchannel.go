package adminactions

import (
	"fmt"
	"github.com/hyperledger/fabric-test/tools/PTE/go/pte"
)

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
	err = pte.ExecuteCommand("node", "node/pte-main.js", createChannelObject)
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	return nil
}