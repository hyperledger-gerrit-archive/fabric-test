package operations

import (
	"encoding/json"
	"strings"

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
	Deploy          Deploy         `json:"deploy,omitempty"`
	ConnProfilePath string         `json:"ConnProfilePath,omitempty"`
}

//Deploy --
type Deploy struct {
	ChainCodePath string `json:"chaincodePath,omitempty"`
	MetadataPath  string `json:"metadataPath,omitempty"`
	Language      string `json:"language,omitempty"`
}

//InstallChainCode --
func (i InstallChainCodeObject) InstallChainCode(config helper.Config) error {

	var installCCObjects []InstallChainCodeObject
	var tls string
	switch tls {
	case "true":
		tls = "enabled"
	case "false":
		tls = "disabled"
	case "mutual":
		tls = "clientauth"
	}
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
	var deploy Deploy
	i = InstallChainCodeObject{TransType: "install", TLS: tls, ChainCodeVer: ccObject.ChainCodeVersion}
	orgNames := strings.Split(ccObject.Organizations, ",")
	for _, orgName := range orgNames {
		orgName = strings.TrimSpace(orgName)
		channelOpt = ChannelOptions{OrgName: []string{orgName}}
		deploy = Deploy{ChainCodePath: ccObject.ChainCodePath, MetadataPath: ccObject.MetadataPath, Language: ccObject.Language}
		i.ChannelOpt = channelOpt
		i.Deploy = deploy
		i.ConnProfilePath = i.getConnProfilePathForOrg(orgName, organizations)
		installCCObjects = append(installCCObjects, i)
	}
	return installCCObjects
}

func (i InstallChainCodeObject) getConnProfilePathForOrg(orgName string, organizations []helper.Organization) string {

	var connProfilePath string
	for i := 0; i < len(organizations); i++ {
		if organizations[i].Name == orgName {
			connProfilePath = organizations[i].ConnProfilePath
		}
	}
	return connProfilePath
}

func (i InstallChainCodeObject) installChaincode(installChainCodeObjects []InstallChainCodeObject) error {

	var err error
	var jsonObject []byte
	for j := 0; j < len(installChainCodeObjects); j++ {
		jsonObject, err = json.Marshal(installChainCodeObjects[j])
		if err != nil {
			return err
		}
		pteMainPath := paths.PTEPath()
		_, err = networkclient.ExecuteCommand("node", []string{pteMainPath, string(jsonObject)}, true)
		if err != nil {
			return err
		}
	}
	return err
}
