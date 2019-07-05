// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
package main

import (
    "flag"
    "fmt"
    "io"
    "io/ioutil"
    "log"
    "net/http"
    "os"
    "path/filepath"
    "runtime"
    NL "github.com/hyperledger/fabric-test/tools/NL/k8s/nl"
    yaml "gopkg.in/yaml.v2"
)

func readArguments() (*string, *string, string) {

    networkSpecPath := flag.String("i", "", "Network spec input file path")
    kubeConfigPath := flag.String("k", "", "Kube config file path")
    mode := flag.String("m", "up", "Set mode(up or down)")
    flag.Parse()

    if fmt.Sprintf("%s", *kubeConfigPath) == "" {
        log.Fatalf("Kube config file not provided")
    } else if fmt.Sprintf("%s", *networkSpecPath) == "" {
        log.Fatalf("Input file not provided")
    }

    return networkSpecPath, kubeConfigPath, fmt.Sprintf("%s", *mode)
}

func downloadYtt() {
    if _, err := os.Stat("ytt"); os.IsNotExist(err) {
        name := runtime.GOOS
        url := fmt.Sprintf("https://github.com/k14s/ytt/releases/download/v0.13.0/ytt-%v-amd64", name)

        resp, err := http.Get(url)
        if err != nil {
            fmt.Println("Error while downloading the ytt, err: %v", err)
        }
        defer resp.Body.Close()
        ytt, err := os.Create("ytt")

        defer ytt.Close()
        io.Copy(ytt, resp.Body)
        err = os.Chmod("ytt", 0777)
        if err != nil {
            fmt.Println("Failed to change permissions to ytt, err: %v", err)
        }
    }
}

func getConf(networkSpecPath string) NL.Config {

    var config NL.Config
    yamlFile, err := ioutil.ReadFile(networkSpecPath)
    if err != nil {
        log.Fatalf("Failed to read input file; err = %v", err)
    }
    err = yaml.Unmarshal(yamlFile, &config)
    if err != nil {
        log.Fatalf("Failed to create config object; err = %v", err)
    }
    return config
}

func generateConfigurationFiles() error {
    err := NL.ExecuteCommand("./ytt", "-f", "./templates/", "--output", "./configFiles")
    if err != nil {
        return err
    }
    return nil
}

func generateCryptoCerts(networkSpec NL.Config) error {

    configPath := filepath.Join(networkSpec.ArtifactsLocation, "crypto-config")
    err := NL.ExecuteCommand("cryptogen", "generate", "--config=./configFiles/crypto-config.yaml", fmt.Sprintf("--output=%v", configPath))
    if err != nil {
        return err
    }
    return nil
}

func generateGenesisBlockNChannelTransaction(networkSpec NL.Config, kubeConfigPath string) error {

    path := filepath.Join(networkSpec.ArtifactsLocation, "channel-artifacts")
    _ = os.Mkdir(path, 0755)

    err := NL.ExecuteCommand("configtxgen", "-profile", "testOrgsOrdererGenesis", "-channelID", "orderersystemchannel", "-outputBlock", fmt.Sprintf("%v/genesis.block", path), "-configPath=./configFiles/")
    if err != nil {
        return err
    }

    kubeconfig := fmt.Sprintf("--kubeconfig=%v", kubeConfigPath)
    err = NL.ExecuteCommand("kubectl", kubeconfig, "create", "secret", "generic", "genesisblock", fmt.Sprintf("--from-file=%v/genesis.block", path))
    if err != nil {
        return err
    }

    path = filepath.Join(networkSpec.ArtifactsLocation, "channel-artifacts")
    _ = os.Mkdir(path, 0755)

    for i := 0; i < networkSpec.NumChannels; i++ {
        err := NL.ExecuteCommand("configtxgen", "-profile", "testorgschannel", "-channelCreateTxBaseProfile", "testOrgsOrdererGenesis", "-channelID", fmt.Sprintf("testorgschannel%v", i), "-outputCreateChannelTx", fmt.Sprintf("%v/testorgschannel%v.tx", path, i), "-configPath=./configFiles/")
        if err != nil {
            return err
        }
    }
    return nil
}

func launchK8sComponents(kubeConfigPath string, isDataPersistance bool) error {

    kubeconfig := fmt.Sprintf("--kubeconfig=%v", kubeConfigPath)

    err := NL.ExecuteCommand("kubectl", kubeconfig, "create", "configmap", "certsparser", "--from-file=./scripts/certs-parser.sh")
    if err != nil {
        return err
    }

    err = NL.ExecuteCommand("kubectl", kubeconfig, "apply", "-f", "./configFiles/k8s-service.yaml", "-f", "./configFiles/fabric-k8s-pods.yaml")
    if err != nil {
        return err
    }

    if isDataPersistance == true {
        err = NL.ExecuteCommand("kubectl", kubeconfig, "apply", "-f", "./configFiles/fabric-pvc.yaml")
        if err != nil {
            return err
        }
    }

    return nil
}


func networkCleanUp(networkSpec NL.Config, kubeConfigPath string) error {

    kubeconfig := fmt.Sprintf("--kubeconfig=%v", kubeConfigPath)
    for i := 0; i < len(networkSpec.OrdererOrganizations); i++ {
        for j := 0; j < networkSpec.OrdererOrganizations[i].NumOrderers; j++ {
            ordererName := fmt.Sprintf("orderer%v-%v", j, networkSpec.OrdererOrganizations[i].Name)
            err := NL.ExecuteCommand("kubectl", kubeconfig, "delete", "secrets", ordererName)
            if err != nil {
                fmt.Println(err.Error())
            }
        }
        for j := 0; j < networkSpec.OrdererOrganizations[i].NumCa; j++ {
            caName := fmt.Sprintf("ca%v-%v", j, networkSpec.OrdererOrganizations[i].Name)
            err := NL.ExecuteCommand("kubectl", kubeconfig, "delete", "secrets", caName)
            if err != nil {
                fmt.Println(err.Error())
            }
        }
    }

    for i := 0; i < len(networkSpec.PeerOrganizations); i++ {
        for j := 0; j < networkSpec.PeerOrganizations[i].NumPeers; j++ {
            peerName := fmt.Sprintf("peer%v-%v", j, networkSpec.PeerOrganizations[i].Name)
            err := NL.ExecuteCommand("kubectl", kubeconfig, "delete", "secrets", peerName)
            if err != nil {
                fmt.Println(err.Error())
            }
        }
        for j := 0; j < networkSpec.PeerOrganizations[i].NumCa; j++ {
            caName := fmt.Sprintf("ca%v-%v", j, networkSpec.PeerOrganizations[i].Name)
            err := NL.ExecuteCommand("kubectl", kubeconfig, "delete", "secrets", caName)
            if err != nil {
                fmt.Println(err.Error())
            }
        }
    }
    err := NL.ExecuteCommand("kubectl", kubeconfig, "delete", "secrets", "genesisblock")
    err = NL.ExecuteCommand("kubectl", kubeconfig, "delete", "-f", "./configFiles/fabric-k8s-pods.yaml")
    err = NL.ExecuteCommand("kubectl", kubeconfig, "delete", "-f", "./configFiles/k8s-service.yaml")
    err = NL.ExecuteCommand("kubectl", kubeconfig, "delete", "-f", "./configFiles/fabric-pvc.yaml")
    err = NL.ExecuteCommand("kubectl", kubeconfig, "delete", "configmaps", "certsparser")
    if err != nil {
        fmt.Println(err.Error())
    }

    currentDir, err := os.Getwd()
    if err != nil {
        err := fmt.Errorf("%v", err)
        fmt.Println(err.Error())
    }
    path := filepath.Join(currentDir, "configFiles")
    err = os.RemoveAll(path)
    path = filepath.Join(currentDir, "templates/input.yaml")
    err = os.RemoveAll(path)
    path = filepath.Join(networkSpec.ArtifactsLocation, "channel-artifacts")
    err = os.RemoveAll(path)
    path = filepath.Join(networkSpec.ArtifactsLocation, "crypto-config")
    err = os.RemoveAll(path)
    if err != nil {
        return err
    }
    return nil
}

func modeAction(mode string, input NL.Config, kubeConfigPath string) {

    switch mode {
    case "up":
        err := generateConfigurationFiles()
        if err != nil {
            log.Fatalf("Failed to generate yaml files; err = %v", err)
        }

        err = generateCryptoCerts(input)
        if err != nil {
            log.Fatalf("Failed to generate certificates; err = %v", err)
        }

        err = NL.CreateMspSecret(input, kubeConfigPath)
        if err != nil {
            log.Fatalf("Failed to create secret; err = %v", err)
        }

        err = generateGenesisBlockNChannelTransaction(input, kubeConfigPath)
        if err != nil {
            log.Fatalf("Failed to create orderer genesis block; err = %v", err)
        }

        err = launchK8sComponents(kubeConfigPath, input.K8s.DataPersistance)
        if err != nil {
            log.Fatalf("Failed to launch k8s components; err = %v", err)
        }

        err = NL.CreateConnectionProfile(input, kubeConfigPath)

        if err != nil {
            log.Fatalf("Failed to launch k8s components; err = %v", err)
        }

    case "down":
        err := networkCleanUp(input, kubeConfigPath)
        if err != nil {
            log.Fatalf("Failed to clean up the network:; err = %v", err)
        }

    default:
        log.Fatalf("Incorrect mode (%v). Use up or down for mode", mode)
    }
}

func main() {

    networkSpecPath, kubeConfigPath, mode := readArguments()
    downloadYtt()
    inputPath := fmt.Sprintf("%s", *networkSpecPath)
    contents, _ := ioutil.ReadFile(inputPath)
    contents = append([]byte("#@data/values \n"), contents...)
    ioutil.WriteFile("templates/input.yaml", contents, 0644)
    inputPath = "templates/input.yaml"
    input := getConf(inputPath)
    modeAction(mode, input, *kubeConfigPath)
}