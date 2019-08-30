package operations

import (
	"encoding/json"
	"strings"
	"fmt"
	"time"
	"strconv"

	"github.com/hyperledger/fabric-test/tools/operator/networkclient"
	"github.com/hyperledger/fabric-test/tools/operator/paths"
	"github.com/hyperledger/fabric-test/tools/operator/testclient/helper"
)

//InstallChainCodeObject --
type InstallChainCodeObject struct {
	TransType       string         `json:"transType,omitempty"`
	TLS             string         `json:"TLS,omitempty"`
	ChainCodeID     string         `json:"chaincodeID,omitempty"`
	ChainCodeVer    string         `json:"chaincodeVer,omitempty"`
	ChannelOpt      ChannelOptions `json:"channelOpt,omitempty"`
	DeployOpt       InstallCCDeployOpt         `json:"deploy,omitempty"`
	ConnProfilePath string         `json:"ConnProfilePath,omitempty"`
}

//InstallCCDeployOpt --
type InstallCCDeployOpt struct {
	ChainCodePath string `json:"chaincodePath,omitempty"`
	MetadataPath  string `json:"metadataPath,omitempty"`
	Language         string `yaml:"language,omitempty"`
}

//InstallChainCode --
func (i InstallChainCodeObject) InstallChainCode(config helper.Config, tls string) error {

	var installCCObjects []InstallChainCodeObject
	for index := 0; index < len(config.InstallCC); index++ {
		ccObjects := i.installChainCodeObjects(config.InstallCC[index], config.Organizations, tls)
		installCCObjects = append(installCCObjects, ccObjects...)
	}
	err := i.installChaincode(installCCObjects)
	if err != nil {
		return err
	}
	return nil
}

func (i InstallChainCodeObject) installChainCodeObjects(ccObject helper.InstallCC, organizations []helper.Organization, tls string) []InstallChainCodeObject {

	var installCCObjects []InstallChainCodeObject
	var channelOpt ChannelOptions
	var deployOpt InstallCCDeployOpt
	i = InstallChainCodeObject{TransType: "install", TLS: tls, ChainCodeVer: ccObject.ChainCodeVersion, ChainCodeID: ccObject.ChainCodeName}
	orgNames := strings.Split(ccObject.Organizations, ",")
	for _, orgName := range orgNames {
		orgName = strings.TrimSpace(orgName)
		channelOpt = ChannelOptions{OrgName: []string{orgName}, Name: "dummychannel"}
		chainCodePath := paths.JoinPath(ccObject.ChainCodePath, ccObject.Language)
		deployOpt = InstallCCDeployOpt{ChainCodePath: chainCodePath, Language: ccObject.Language}
		if ccObject.MetadataPath != "" {
			deployOpt.MetadataPath = ccObject.MetadataPath
		}
		i.DeployOpt = deployOpt
		i.ChannelOpt = channelOpt
		i.ConnProfilePath = paths.GetConnProfilePathForOrg(orgName, organizations)
		installCCObjects = append(installCCObjects, i)
	}
	return installCCObjects
}

func (i InstallChainCodeObject) installChaincode(installChainCodeObjects []InstallChainCodeObject) error {

	var err error
	var jsonObject []byte
	pteMainPath := paths.PTEPath()
	for j := 0; j < len(installChainCodeObjects); j++ {
		jsonObject, err = json.Marshal(installChainCodeObjects[j])
		if err != nil {
			return err
		}
		startTime := fmt.Sprintf("%s", time.Now())
		args := []string{pteMainPath, strconv.Itoa(j), string(jsonObject), startTime}
		_, err = networkclient.ExecuteCommand("node", args, true)
		if err != nil {
			return err
		}
	}
	return err
}