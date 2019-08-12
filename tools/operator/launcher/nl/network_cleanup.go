// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	"fmt"
	"os"
	"path/filepath"

    "github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
)

//NetworkCleanUp - to clean up the network
func NetworkCleanUp(input networkspec.Config, kubeConfigPath string) error {
    var err error
    if kubeConfigPath != "" {
        numOrdererOrganizations := len(input.OrdererOrganizations)
        for i := 0; i < numOrdererOrganizations; i++ {
            ordererOrg := input.OrdererOrganizations[i]
            numOrderers := ordererOrg.NumOrderers
            deleteType(numOrderers, ordererOrg.NumCA, "orderer", input.OrdererOrganizations[i].Name, kubeConfigPath, input.TLS)
        }

        for i := 0; i < len(input.PeerOrganizations); i++ {
            deleteType(input.PeerOrganizations[i].NumPeers, input.PeerOrganizations[i].NumCA, "peer", input.PeerOrganizations[i].Name, kubeConfigPath, input.TLS)
        }
        err = client.ExecuteK8sCommand(kubeConfigPath, "delete", "secrets", "genesisblock")
        err = client.ExecuteK8sCommand(kubeConfigPath, "delete", "-f", "./../configFiles/fabric-k8s-pods.yaml")
        if input.K8s.DataPersistence == "local" {
            err = client.ExecuteK8sCommand(kubeConfigPath, "apply", "-f", "./scripts/alpine.yaml")
        }
        err = client.ExecuteK8sCommand(kubeConfigPath, "delete", "-f", "./../configFiles/fabric-k8s-service.yaml")
        if input.K8s.DataPersistence == "true" {
            err = client.ExecuteK8sCommand(kubeConfigPath, "delete", "-f", "./../configFiles/fabric-k8s-pvc.yaml")
        }
    } else {
        err = client.ExecuteCommand("docker-compose", "-f", "./../configFiles/docker-compose.yaml", "down")
    }
    if err != nil {
        fmt.Println(err.Error())
    }

    err = os.RemoveAll("../configFiles")
    err = os.RemoveAll("../templates/input.yaml")
    path := filepath.Join(input.ArtifactsLocation, "channel-artifacts")
    err = os.RemoveAll(path)
    path = filepath.Join(input.ArtifactsLocation, "crypto-config")
    err = os.RemoveAll(path)
    path = filepath.Join(input.ArtifactsLocation, "connection-profile")
    err = os.RemoveAll(path)
    if input.K8s.DataPersistence == "local" && kubeConfigPath != "" {
        err = client.ExecuteK8sCommand(kubeConfigPath, "delete", "-f", "./scripts/alpine.yaml")
    }
    if err != nil {
        return err
    }
    return nil
}

func deleteType(numComponents int, numCa int, componentType, orgName, kubeConfigPath, tls string) {

    for j := 0; j < numComponents; j++ {
        componentName := fmt.Sprintf("%v%v-%v", componentType, j, orgName)
        err := client.ExecuteK8sCommand(kubeConfigPath, "delete", "configmap", fmt.Sprintf("%s-msp", componentName), fmt.Sprintf("%s-tls", componentName))
        if err != nil {
            fmt.Println(err.Error())
        }
    }
    if numCa > 0 {
        err := client.ExecuteK8sCommand(kubeConfigPath, "delete", "configmap", fmt.Sprintf("%s-ca", orgName))
        if err != nil {
            fmt.Println(err.Error())
        }
    }

    if (componentType == "peer" || componentType == "orderer") && tls == "mutual" {
        err := client.ExecuteK8sCommand(kubeConfigPath, "delete", "secrets", fmt.Sprintf("%v-clientrootca-secret", orgName))
        if err != nil {
            fmt.Println(err.Error())
        }
    }
}
