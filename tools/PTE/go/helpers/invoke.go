package helpers

import (
	"fmt"
)

//InvokeTransactions -- To send traffic
func InvokeTransactions(inputFilePath string) error {

	_, err := GetInputData(inputFilePath)
	if err != nil {
		return err
	}

	return nil
}