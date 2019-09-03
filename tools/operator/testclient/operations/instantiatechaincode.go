package operations

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"strconv"
	"strings"
	"time"

	"github.com/hyperledger/fabric-test/tools/operator/logger"
	"github.com/hyperledger/fabric-test/tools/operator/networkclient"
	"github.com/hyperledger/fabric-test/tools/operator/paths"
	"github.com/hyperledger/fabric-test/tools/operator/testclient/helper"
	yaml "gopkg.in/yaml.v2"
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
	Function    string            `json:"fcn,omitempty"`
	Arguments   []string          `json:"args,omitempty"`
	Endorsement EndorsementPolicy `json:"endorsement,omitempty"`
}

//TimeOutOptions --
type TimeOutOptions struct {
	PreConfig string `json:"preConfig,omitempty"`
	Request   string `json:"request,omitempty"`
}

type EndorsementPolicy struct {
	Identities []Identity          `json:"identities,omitempty"`
	Policy     map[string][]Policy `json:"policy,omitempty"`
}

type Policy struct {
	SignedBy int `json:"signed-by,omitempty"`
}

type Identity struct {
	Role struct {
		Name  string `json:"name,omitempty"`
		MSPID string `json:"mspId,omitempty"`
	} `json:"role,omitempty"`
}

type GetMSPID struct {
	Organizations map[string]struct {
		MSPID string `yaml:"mspid,omitempty"`
	} `yaml:"organizations,omitempty"`
}

//InstantiateChainCode --
func (i InstantiateChainCodeObject) InstantiateChainCode(config helper.Config, tls string) error {

	var instantiateCCObjects []InstantiateChainCodeObject
	for index := 0; index < len(config.InstantiateCC); index++ {
		ccObjects, err := i.generateInstantiateCCObjects(config.InstantiateCC[index], config.Organizations, tls)
		if err != nil {
			return err
		}
		instantiateCCObjects = append(instantiateCCObjects, ccObjects...)
	}
	err := i.instantiateChainCode(instantiateCCObjects)
	if err != nil {
		return err
	}
	return nil
}

func (i InstantiateChainCodeObject) generateInstantiateCCObjects(ccObject helper.InstantiateCC, organizations []helper.Organization, tls string) ([]InstantiateChainCodeObject, error) {

	var instantiateCCObjects []InstantiateChainCodeObject
	var err error
	if ccObject.ChannelPrefix != "" && ccObject.NumChannels > 0 {
		instantiateCCObjects, err = i.createInstantiateCCObjectIfChanPrefix(ccObject, organizations, tls)
		if err != nil {
			return instantiateCCObjects, err
		}
		return instantiateCCObjects, nil
	}
	orgNames := strings.Split(ccObject.Organizations, ",")
	instantiateCCObjects, err = i.createInstantiateCCObjects(orgNames, ccObject.ChannelName, tls, organizations, ccObject)
	if err != nil {
		return instantiateCCObjects, err
	}
	return instantiateCCObjects, nil
}

func (i InstantiateChainCodeObject) createInstantiateCCObjects(orgNames []string, channelName, tls string, organizations []helper.Organization, ccObject helper.InstantiateCC) ([]InstantiateChainCodeObject, error) {

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
		if ccObject.EndorsementPolicy != "" {
			endorsementPolicy, err := i.getEndorsementPolicy(organizations, ccObject.EndorsementPolicy)
			if err != nil {
				logger.ERROR("Failed to get the endorsement policy")
				return instantiateCCObjects, err
			}
			i.DeployOpt.Endorsement = endorsementPolicy
		}
		instantiateCCObjects = append(instantiateCCObjects, i)
	}
	return instantiateCCObjects, nil
}

func (i InstantiateChainCodeObject) createInstantiateCCObjectIfChanPrefix(ccObject helper.InstantiateCC, organizations []helper.Organization, tls string) ([]InstantiateChainCodeObject, error) {

	var instantiateCCObjects []InstantiateChainCodeObject
	var channelName string
	for j := 0; j < ccObject.NumChannels; j++ {
		channelName = fmt.Sprintf("%s%s", ccObject.ChannelPrefix, strconv.Itoa(j))
		orgNames := strings.Split(ccObject.Organizations, ",")
		ccObjects, err := i.createInstantiateCCObjects(orgNames, channelName, tls, organizations, ccObject)
		if err != nil {
			return instantiateCCObjects, err
		}
		instantiateCCObjects = append(instantiateCCObjects, ccObjects...)
	}
	return instantiateCCObjects, nil
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

func (i InstantiateChainCodeObject) getEndorsementPolicy(organizations []helper.Organization, policy string) (EndorsementPolicy, error) {

	var endorsementPolicy EndorsementPolicy
	var identities []Identity
	var policies []Policy
	var identity Identity
	args := strings.Split(policy, "(")
	orgs := args[len(args)-1]
	orgs = orgs[:len(orgs)-1]
	orgNames := strings.Split(orgs, ",")
	for _, orgName := range orgNames {
		orgName = strings.TrimSpace(orgName)
		connProfilePath := helper.GetConnProfilePathForOrg(orgName, organizations)
		mspID, err := i.getMSPIDForOrg(connProfilePath, orgName)
		if err != nil {
			return endorsementPolicy, err
		}
		identity.Role.Name = "member"
		identity.Role.MSPID = mspID
		identities = append(identities, identity)
	}
	numPolicies, err := strconv.Atoi(args[0][0:1])
	if err != nil {
		logger.ERROR("Failed to convert string to integer")
		return endorsementPolicy, err
	}
	key := fmt.Sprintf("%d-of", numPolicies)
	for i := 0; i < numPolicies; i++ {
		policy := Policy{SignedBy: i + 1}
		policies = append(policies, policy)
	}
	policyMap := make(map[string][]Policy)
	policyMap[key] = policies
	endorsementPolicy = EndorsementPolicy{Identities: identities, Policy: policyMap}
	return endorsementPolicy, nil
}

func (i InstantiateChainCodeObject) getMSPIDForOrg(connProfilePath, orgName string) (string, error) {
	var config GetMSPID
	var mspID string
	yamlFile, err := ioutil.ReadFile(connProfilePath)
	if err != nil {
		logger.ERROR("Failed to read connectionprofile to get MSPID ")
		return mspID, err
	}
	err = yaml.Unmarshal(yamlFile, &config)
	if err != nil {
		logger.ERROR("Failed to create GetMSPID object")
		return mspID, err
	}
	mspID = config.Organizations[orgName].MSPID
	return mspID, nil
}
