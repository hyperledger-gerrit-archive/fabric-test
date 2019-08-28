package helpers

import (
	"fmt"
	"github.com/hyperledger/fabric-test/tools/PTE/go/pte"
)

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
	err = pte.ExecuteCommand("node", "node/pte-main.js", instantiateCCObject)
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	return nil
}