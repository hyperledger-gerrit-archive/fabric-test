// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	"fmt"
	"os"
	"path/filepath"
)

func NetworkCleanUp(networkSpec Config, kubeConfigPath string) error {

    for i := 0; i < len(networkSpec.OrdererOrganizations); i++ {
        for j := 0; j < networkSpec.OrdererOrganizations[i].NumOrderers; j++ {
            ordererName := fmt.Sprintf("orderer%v-%v", j, networkSpec.OrdererOrganizations[i].Name)
            err := ExecuteK8sCommand(kubeConfigPath, "delete", "secrets", ordererName)
            if err != nil {
                fmt.Println(err.Error())
            }
        }
        for j := 0; j < networkSpec.OrdererOrganizations[i].NumCa; j++ {
            caName := fmt.Sprintf("ca%v-%v", j, networkSpec.OrdererOrganizations[i].Name)
            err := ExecuteK8sCommand(kubeConfigPath, "delete", "secrets", caName)
            if err != nil {
                fmt.Println(err.Error())
            }
        }
    }

    for i := 0; i < len(networkSpec.PeerOrganizations); i++ {
        for j := 0; j < networkSpec.PeerOrganizations[i].NumPeers; j++ {
            peerName := fmt.Sprintf("peer%v-%v", j, networkSpec.PeerOrganizations[i].Name)
            err := ExecuteK8sCommand( kubeConfigPath, "delete", "secrets", peerName)
            if err != nil {
                fmt.Println(err.Error())
            }
        }
        for j := 0; j < networkSpec.PeerOrganizations[i].NumCa; j++ {
            caName := fmt.Sprintf("ca%v-%v", j, networkSpec.PeerOrganizations[i].Name)
            err := ExecuteK8sCommand( kubeConfigPath, "delete", "secrets", caName)
            if err != nil {
                fmt.Println(err.Error())
            }
        }
    }
    err := ExecuteK8sCommand(kubeConfigPath, "delete", "secrets", "genesisblock")
    err = ExecuteK8sCommand( kubeConfigPath, "delete", "-f", "./configFiles/fabric-k8s-pods.yaml")
    err = ExecuteK8sCommand( kubeConfigPath, "delete", "-f", "./configFiles/k8s-service.yaml")
    err = ExecuteK8sCommand( kubeConfigPath, "delete", "-f", "./configFiles/fabric-pvc.yaml")
    err = ExecuteK8sCommand( kubeConfigPath, "delete", "configmaps", "certsparser")
    if err != nil {
        fmt.Println(err.Error())
    }

    err = os.RemoveAll("configFiles")
    err = os.RemoveAll("templates/input.yaml")
    path := filepath.Join(networkSpec.ArtifactsLocation, "channel-artifacts")
    err = os.RemoveAll(path)
    path = filepath.Join(networkSpec.ArtifactsLocation, "crypto-config")
    err = os.RemoveAll(path)
    if err != nil {
        return err
    }
    return nil
}