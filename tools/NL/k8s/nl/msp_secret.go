package nl

import (
    "encoding/json"
    "fmt"
    "io/ioutil"
    "path/filepath"
    "strings"
)

func CreateMspJson(networkSpec Config, path string, caPath string, componentName string, kubeConfigPath string) error {

    var msp MSP
    var tls TLS
    var ca CA
    var tlsCa TlsCa
    var component Component
    var tlsArr []string
    if strings.HasPrefix(componentName, "orderer") || strings.HasPrefix(componentName, "peer") {
        files, err := ioutil.ReadDir(path)
        if err != nil {
            return err
        }
        dir := path
        for _, f := range files {
            if f.Name() == "msp" {
                mspDir, _ := ioutil.ReadDir(fmt.Sprintf("%v/msp", dir))
                var mspArr []string
                for _, sf := range mspDir {
                    mspSubDir, _ := ioutil.ReadDir(fmt.Sprintf("%v/msp/%v", dir, sf.Name()))
                    for _, j := range mspSubDir {
                        data, _ := ioutil.ReadFile(fmt.Sprintf("%v/msp/%v/%v", dir, sf.Name(), j.Name()))
                        mspArr = append(mspArr, string(data))
                    }
                }
                msp.AdminCerts.AdminPem = mspArr[0]
                msp.CACerts.CaPem = mspArr[1]
                msp.Keystore.PrivateKey = mspArr[2]
                msp.SignCerts.OrdererPem = mspArr[3]
                msp.TlsCaCerts.TlsPem = mspArr[4]
            } else {
                tlsDir, _ := ioutil.ReadDir(fmt.Sprintf("%v/tls", dir))
                for _, sf := range tlsDir {
                    data, _ := ioutil.ReadFile(fmt.Sprintf("%v/tls/%v", dir, sf.Name()))
                    tlsArr = append(tlsArr, string(data))
                }
                tls.CaCert = tlsArr[0]
                tls.ServerCert = tlsArr[1]
                tls.ServerKey = tlsArr[2]
            }
        }
        component.Msp = msp
        component.Tls = tls
    }

    files, err := ioutil.ReadDir(caPath)
    if err != nil {
        return err
    }

    for _, f := range files {
        dir := fmt.Sprintf("%v/%v", caPath, f.Name())
        if f.Name() == "ca" {
            caDir, _ := ioutil.ReadDir(fmt.Sprintf("%v/", dir))
            caCerts := make(map[string]string)
            for _, file := range caDir {
                data, _ := ioutil.ReadFile(fmt.Sprintf("%v/%v", dir, file.Name()))
                if strings.HasSuffix(file.Name(), "pem") {
                    caCerts["pem"] = string(data)
                } else {
                    caCerts["private_key"] = string(data)
                }
            }
            ca.PrivateKey = caCerts["private_key"]
            ca.Pem = caCerts["pem"]
        } else if f.Name() == "tlsca" {
            tlsCaDir, _ := ioutil.ReadDir(fmt.Sprintf("%v/", dir))
            tlsCaCerts := make(map[string]string)
            for _, file := range tlsCaDir {
                data, _ := ioutil.ReadFile(fmt.Sprintf("%v/%v", dir, file.Name()))
                if strings.HasSuffix(file.Name(), "pem") {
                    tlsCaCerts["pem"] = string(data)
                } else {
                    tlsCaCerts["private_key"] = string(data)
                }
            }
            tlsCa.PrivateKey = tlsCaCerts["private_key"]
            tlsCa.Pem = tlsCaCerts["pem"]
        }
    }

    component.Ca = ca
    component.Tlsca = tlsCa
    b, _ := json.MarshalIndent(component, "", "  ")
    _ = ioutil.WriteFile(fmt.Sprintf("./configFiles/%v.json", componentName), b, 0644)

    err = ExecuteCommand("kubectl", fmt.Sprintf("--kubeconfig=%v", kubeConfigPath), "create", "secret", "generic", fmt.Sprintf("%v", componentName), fmt.Sprintf("--from-file=./configFiles/%v.json", componentName))
    if err != nil {
        return err
    }

    return nil
}

func CreateMspSecret(networkSpec Config, kubeConfigPath string) error {

    for i := 0; i < len(networkSpec.OrdererOrganizations); i++ {
        for j := 0; j < networkSpec.OrdererOrganizations[i].NumOrderers; j++ {
            ordererName := fmt.Sprintf("orderer%s-%s", fmt.Sprintf("%v", j), networkSpec.OrdererOrganizations[i].Name)
            caPath := filepath.Join(networkSpec.ArtifactsLocation, "crypto-config/ordererOrganizations", networkSpec.OrdererOrganizations[i].Name)
            path := filepath.Join(networkSpec.ArtifactsLocation, "crypto-config/ordererOrganizations", networkSpec.OrdererOrganizations[i].Name+"/orderers/"+ordererName+"."+networkSpec.OrdererOrganizations[i].Name)
            _ = CreateMspJson(networkSpec, path, caPath, ordererName, kubeConfigPath)
        }
        for j := 0; j < networkSpec.OrdererOrganizations[i].NumCa; j++ {
            caName := fmt.Sprintf("ca%s-%s", fmt.Sprintf("%v", j), networkSpec.OrdererOrganizations[i].Name)
            caPath := filepath.Join(networkSpec.ArtifactsLocation, "crypto-config/ordererOrganizations", networkSpec.OrdererOrganizations[i].Name)
            _ = CreateMspJson(networkSpec, "", caPath, caName, kubeConfigPath)
        }
    }

    for i := 0; i < len(networkSpec.PeerOrganizations); i++ {
        for j := 0; j < networkSpec.PeerOrganizations[i].NumPeers; j++ {
            peerName := fmt.Sprintf("peer%s-%s", fmt.Sprintf("%v", j), networkSpec.PeerOrganizations[i].Name)
            path := filepath.Join(networkSpec.ArtifactsLocation, "crypto-config/peerOrganizations", networkSpec.PeerOrganizations[i].Name+"/peers/"+peerName+"."+networkSpec.PeerOrganizations[i].Name)
            caPath := filepath.Join(networkSpec.ArtifactsLocation, "crypto-config/peerOrganizations", networkSpec.PeerOrganizations[i].Name)
            _ = CreateMspJson(networkSpec, path, caPath, peerName, kubeConfigPath)
        }
        for j := 0; j < networkSpec.PeerOrganizations[i].NumCa; j++ {
            caName := fmt.Sprintf("ca%s-%s", fmt.Sprintf("%v", j), networkSpec.PeerOrganizations[i].Name)
            caPath := filepath.Join(networkSpec.ArtifactsLocation, "crypto-config/peerOrganizations", networkSpec.PeerOrganizations[i].Name)
            _ = CreateMspJson(networkSpec, "", caPath, caName, kubeConfigPath)
        }
    }
    return nil
}