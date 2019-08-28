package helpers

import (
	"fmt"
	"github.com/hyperledger/fabric-test/tools/PTE/go/pte"
)

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
	err = pte.ExecuteCommand("node", "node/pte-main.js", joinChannelObject)
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	return nil
}