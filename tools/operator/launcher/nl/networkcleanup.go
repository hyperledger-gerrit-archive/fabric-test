// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	"os"
	"fmt"
	"strings"

	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
)

//NetworkCleanUp - to clean up the network
func (n Network) NetworkCleanUp(config networkspec.Config) error {

	artifactsLocation := config.ArtifactsLocation
	paths := []string{
		utils.ConfigFilesDir(),
		utils.JoinPath(utils.TemplatesDir(), "input.yaml"),
		utils.ChannelArtifactsDir(artifactsLocation),
		utils.CryptoConfigDir(artifactsLocation),
		utils.ConnectionProfilesDir(artifactsLocation)
	}
	err := n.removeDirectories(paths)
	if err != nil{
		return err
	}
	return nil
}

func (n Network) removeDirectories(paths []string) error{
	var err error
	var errors []string
	for i := 0; i < len(paths); i++{
		err = os.RemoveAll(paths[i])
		if err != nil{
			errors = append(errors, err.Error())
		}
	}
	if len(errors) > 0{
		return fmt.Errorf("%s", strings.Join(errors, "\n"))
	}
	return nil
}
