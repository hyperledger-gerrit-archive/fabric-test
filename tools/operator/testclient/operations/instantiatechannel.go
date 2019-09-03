package operations

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"

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
	ConnProfilePath string                   `json:"ConnProfilePath,omitempty"`
	ChannelOpt      ChannelOptions           `json:"channelOpt,omitempty"`
	DeployOpt       InstantiateDeployOptions `json:"deploy,omitempty"`
	TimeOutOpt      TimeOutOptions           `json:"timeoutOpt,timeoutOpt"`
}

//InstantiateDeployOptions --
type InstantiateDeployOptions struct {
	Function  string   `json:"fcn,omitempty"`
	Arguments []string `json:"args,omitempty"`
}

//TimeOutOptions --
type TimeOutOptions struct {
	PreConfig string `json:"preConfig,omitempty"`
	Request   string `json:"request,omitempty"`
}

//InstantiateChainCode --
func (i InstantiateChainCodeObject) InstantiateChainCode(config helper.Config, tls string) error {

	var instantiateCCObjects []InstantiateChainCodeObject
	for index := 0; index < len(config.InstantiateCC); index++ {
		ccObjects := i.generateInstantiateCCObjects(config.InstantiateCC[index], config.Organizations, tls)
		instantiateCCObjects = append(instantiateCCObjects, ccObjects...)
	}
	err := i.instantiateChainCode(instantiateCCObjects)
	if err != nil {
		return err
	}
	return nil
}

func (i InstantiateChainCodeObject) generateInstantiateCCObjects(ccObject helper.InstantiateCC, organizations []helper.Organization, tls string) []InstantiateChainCodeObject {

	var instantiateCCObjects []InstantiateChainCodeObject
	if ccObject.ChannelPrefix != "" && ccObject.NumChannels > 0 {
		instantiateCCObjects = i.createInstantiateCCObjectIfChanPrefix(ccObject, organizations, tls)
		return instantiateCCObjects
	}
	orgNames := strings.Split(ccObject.Organizations, ",")
	instantiateCCObjects = i.createInstantiateCCObjects(orgNames, ccObject.ChannelName, tls, organizations, ccObject)
	return instantiateCCObjects
}

func (i InstantiateChainCodeObject) createInstantiateCCObjects(orgNames []string, channelName, tls string, organizations []helper.Organization, ccObject helper.InstantiateCC) []InstantiateChainCodeObject {

	var instantiateCCObjects []InstantiateChainCodeObject
	for _, orgName := range orgNames {
		orgName = strings.TrimSpace(orgName)
		i = InstantiateChainCodeObject{TransType: "instantiate", TLS: tls, ConnProfilePath: helper.GetConnProfilePathForOrg(orgName, organizations), ChainCodeID: ccObject.ChainCodeName, ChainCodeVer: ccObject.ChainCodeVersion}
		i.ChannelOpt = ChannelOptions{Name: channelName, Action: "create", OrgName: []string{orgName}}
		i.DeployOpt = InstantiateDeployOptions{Function: "init", Arguments: strings.Split(ccObject.Arguments, ",")}
		i.TimeOutOpt = TimeOutOptions{PreConfig: ccObject.TimeOutOpt.PreConfig, Request: ccObject.TimeOutOpt.Request}
		if ccObject.TimeOutOpt.PreConfig == "" {
			i.TimeOutOpt = TimeOutOptions{PreConfig: "600000", Request: "600000"}
		}
		instantiateCCObjects = append(instantiateCCObjects, i)
	}
	return instantiateCCObjects
}

func (i InstantiateChainCodeObject) createInstantiateCCObjectIfChanPrefix(ccObject helper.InstantiateCC, organizations []helper.Organization, tls string) []InstantiateChainCodeObject {

	var instantiateCCObjects []InstantiateChainCodeObject
	var channelName string
	for j := 0; j < ccObject.NumChannels; j++ {
		channelName = fmt.Sprintf("%s%s", ccObject.ChannelPrefix, strconv.Itoa(j))
		orgNames := strings.Split(ccObject.Organizations, ",")
		ccObjects := i.createInstantiateCCObjects(orgNames, channelName, tls, organizations, ccObject)
		instantiateCCObjects = append(instantiateCCObjects, ccObjects...)
	}
	return instantiateCCObjects
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
		startTime := fmt.Sprintf("%s", time.Now())
		args := []string{pteMainPath, strconv.Itoa(j), string(jsonObject), startTime}
		_, err = networkclient.ExecuteCommand("node", args, true)
		if err != nil {
			return err
		}
	}
	return err
}
