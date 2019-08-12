// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	"log"
	"os"

	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/helper"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
)

//NetworkCleanUp - to clean up the network
func NetworkCleanUp(input networkspec.Config, kubeConfigPath string) error {
	var err error
	artifactsLocation := input.ArtifactsLocation
	if kubeConfigPath != "" {
		err = DownK8sComponents(kubeConfigPath, input)
	} else {
		err = DownLocalNetwork()
	}
	if err != nil {
		log.Printf("%s", err)
	}
	err = os.RemoveAll(helper.ConfigFilesDir())
	err = os.RemoveAll(helper.JoinPath(helper.TemplatesDir(), "input.yaml"))
	err = os.RemoveAll(helper.ChannelArtifactsDir(artifactsLocation))
	err = os.RemoveAll(helper.CryptoConfigDir(artifactsLocation))
	err = os.RemoveAll(helper.ConnectionProfilesDir(artifactsLocation))
	if input.K8s.DataPersistence == "local" && kubeConfigPath != "" {
		err = client.ExecuteK8sCommand(kubeConfigPath, true, "delete", "-f", "./scripts/alpine.yaml")
	}
	if err != nil {
		return err
	}
	return nil
}