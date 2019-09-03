package operations

import (
	"encoding/json"
	"strings"

	// "github.com/hyperledger/fabric-test/tools/operator/networkclient"
	// "github.com/hyperledger/fabric-test/tools/operator/paths"
	"github.com/hyperledger/fabric-test/tools/operator/networkclient"
	"github.com/hyperledger/fabric-test/tools/operator/paths"
	"github.com/hyperledger/fabric-test/tools/operator/testclient/helper"
)

//InstantiateChainCodeObject --
type InstantiateChainCodeObject struct {
	TransType       string                   `json:"transType,omitempty"`
	TLS             string                   `json:"TLS,omitempty"`
	ChainCodeID     string                   `json:"chaincodeID,omitempty"`
	ChainCodeVer    string                   `json:"chaincodeVer,omitempty"`
	ChannelOpt      ChannelOptions           `json:"channelOpt,omitempty"`
	Deploy          InstantiateDeployOptions `json:"deploy,omitempty"`
	ConnProfilePath string                   `json:"ConnProfilePath,omitempty"`
	TimeOutObject   TimeOutObject            `json:"channelOpt,timeoutOpt"`
}

//InstantiateDeployOptions --
type InstantiateDeployOptions struct {
	ChainCodePath string   `json:"chaincodePath,omitempty"`
	Language      string   `json:"language,omitempty"`
	Function      string   `json:"fcn,omitempty"`
	Arguments     []string `json:"args,omitempty"`
}

//TimeOutObject --
type TimeOutObject struct {
	PreConfig string `json:"preConfig,omitempty"`
	Request   string `json:"request,omitempty"`
}

//InstantiateChainCode --
func (i InstantiateChainCodeObject) InstantiateChainCode(config helper.Config, tls string) error {

	var instantiateCCObjects []InstantiateChainCodeObject
	for index := 0; index < len(config.InstantiateCC); index++ {
		ccObjects := i.instantiateChainCodeObjects(config.InstantiateCC[index], config.Organizations, tls)
		instantiateCCObjects = append(instantiateCCObjects, ccObjects...)
	}
	err := i.instantiateChainCode(instantiateCCObjects)
	if err != nil {
		return err
	}
	return nil
}

func (i InstantiateChainCodeObject) instantiateChainCodeObjects(ccObject helper.InstantiateCC, organizations []helper.Organization, tls string) []InstantiateChainCodeObject {

	var instantiateCCObjects []InstantiateChainCodeObject
	var channelOpt ChannelOptions
	var deploy InstantiateDeployOptions
	var timeOutOptions TimeOutObject
	i = InstantiateChainCodeObject{TransType: "instantiate", TLS: tls, ChainCodeVer: ccObject.ChainCodeVersion}
	orgNames := strings.Split(ccObject.Organizations, ",")
	for _, orgName := range orgNames {
		orgName = strings.TrimSpace(orgName)
		channelOpt = ChannelOptions{OrgName: []string{orgName}}
		deploy = InstantiateDeployOptions{ChainCodePath: ccObject.ChainCodePath, Language: ccObject.Language}
		timeOutOptions = TimeOutObject{PreConfig: ccObject.TimeOutOpt.PreConfig, Request: ccObject.TimeOutOpt.Request}
		if ccObject.TimeOutOpt.PreConfig == "" {
			timeOutOptions = TimeOutObject{PreConfig: "600000", Request: "600000"}
		}
		i.TimeOutObject = timeOutOptions
		i.ChannelOpt = channelOpt
		i.Deploy = deploy
		i.ConnProfilePath = i.getConnProfilePathForOrg(orgName, organizations)
		instantiateCCObjects = append(instantiateCCObjects, i)
	}
	return instantiateCCObjects
}

func (i InstantiateChainCodeObject) getConnProfilePathForOrg(orgName string, organizations []helper.Organization) string {

	var connProfilePath string
	for i := 0; i < len(organizations); i++ {
		if organizations[i].Name == orgName {
			connProfilePath = organizations[i].ConnProfilePath
		}
	}
	return connProfilePath
}

func (i InstantiateChainCodeObject) instantiateChainCode(instantiateChainCodeObjects []InstantiateChainCodeObject) error {
	var err error
	var jsonObject []byte
	for j := 0; j < len(instantiateChainCodeObjects); j++ {
		jsonObject, err = json.Marshal(instantiateChainCodeObjects[j])
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
