package operations

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"

	"github.com/hyperledger/fabric-test/tools/operator/testclient/helper"
	"github.com/hyperledger/fabric-test/tools/operator/paths"
)

type InvokeQueryObject struct {
	LogLevel    string          `json:"logLevel,omitempty"`
	InvokeCheck string          `json:"invokeCheck,omitempty"`
	TransMode   string          `json:"transMode,omitempty"`
	TransType   string          `json:"transType,omitempty"`
	InvokeType  string          `json:"invokeType,omitempty"`
	TargetPeers string          `json:"targetPeers,omitempty"`
	TLS         string          `json:"TLS,omitempty"`
	NProcPerOrg string          `json:"nProcPerOrg,omitempty"`
	NRequest    string          `json:"nRequest,omitempty"`
	RunDur      string          `json:"runDur,omitempty"`
	ChannelOpt  ChannelOptions  `json:"channelOpt,omitempty"`
	BurstOpt    BurstOptions    `json:"burstOpt,omitempty"`
	MixOpt      MixOptions      `json:"mixOpt,omitempty"`
	ConstOpt    ConstantOptions `json:"constantOpt,omitempty"`
	EventOpt    EventOptions    `json:"eventOpt,omitempty"`
	//ListOpt         map[string][]string `json:"listOpt,omitempty"`
	CCType          string                `json:"ccType,omitempty"`
	CCOpt           CCOptions             `json:"ccOpt,omitempty"`
	Parameters      map[string]Parameters `json:"invoke,omitempty"`
	ConnProfilePath string                `json:"ConnProfilePath,omitempty"`
}

type BurstOptions struct {
	BurstFreq0 string `json:"burstFreq0,omitempty"`
	BurstDur0  string `json:"burstDur0,omitempty"`
	BurstFreq1 string `json:"burstFreq1,omitempty"`
	BurstDur1  string `json:"burstDur1,omitempty"`
}

type MixOptions struct {
	MixFreq string `json:"mixFreq,omitempty"`
}

type ConstantOptions struct {
	RecHist   string `json:"recHist,omitempty"`
	ConstFreq string `json:"constFreq,omitempty"`
	DevFreq   string `json:"devFreq,omitempty"`
}

type EventOptions struct {
	Type     string `json:"type,omitempty"`
	Listener string `json:"listener,omitempty"`
	TimeOut  string `json:"timeout,omitempty"`
}

type CCOptions struct {
	KeyIdx     []int  `json:"keyIdx,omitempty"`
	KeyPayLoad []int  `json:"keyPayLoad,omitempty"`
	KeyStart   string `json:"keyStart,omitempty"`
	PayLoadMin string `json:"payLoadMin,omitempty"`
	PayLoadMax string `json:"payLoadMax,omitempty"`
}

type Parameters struct {
	Fcn  string   `json:"fcn,omitempty"`
	Args []string `json:"args,omitempty"`
}

func (i InvokeQueryObject) InvokeQuery(config helper.Config, tls, action string) error {

	var InvokeQueryObjects []InvokeQueryObject
	var err error
	for key := range config.InvokeQuery {
		invkQueryObjects := i.generateInvokeQueryObjects(config.InvokeQuery[key], config.Organizations, tls, action)
		InvokeQueryObjects = append(InvokeQueryObjects, invkQueryObjects...)
	}
	err = i.invokeTransactions(InvokeQueryObjects)
	if err != nil {
		return err
	}
	return err
}

func (i InvokeQueryObject) generateInvokeQueryObjects(invkQueryObject helper.InvokeQuery, organizations []helper.Organization, tls, action string) []InvokeQueryObject {

	var InvokeQueryObjects []InvokeQueryObject
	orgNames := strings.Split(invkQueryObject.Organizations, ",")
	for _, orgName := range orgNames {
		orgName = strings.TrimSpace(orgName)
		invkQueryObjects := i.createInvokeQueryObjectForOrg(orgName, action, tls, organizations, invkQueryObject)
		InvokeQueryObjects = append(InvokeQueryObjects, invkQueryObjects...)
	}
	return InvokeQueryObjects
}

func (i InvokeQueryObject) createInvokeQueryObjectForOrg(orgName, action, tls string, organizations []helper.Organization, invkQueryObject helper.InvokeQuery) []InvokeQueryObject {

	var InvokeQueryObjects []InvokeQueryObject
	invokeParams := make(map[string]Parameters)
	invokeCheck := "TRUE"
	if invkQueryObject.QueryCheck > 0 {
		invokeCheck = "FALSE"
	}
	i = InvokeQueryObject{LogLevel: "ERROR", InvokeCheck: invokeCheck, TransType: action, InvokeType: "Move", TargetPeers: invkQueryObject.TargetPeers, TLS: tls, NProcPerOrg: strconv.Itoa(invkQueryObject.NProcPerOrg), NRequest: strconv.Itoa(invkQueryObject.NRequest), RunDur: strconv.Itoa(invkQueryObject.RunDuration), CCType: invkQueryObject.CCOptions.CCType}
	i.ChannelOpt = ChannelOptions{Name: invkQueryObject.ChannelName, OrgName: []string{orgName}}
	i.CCOpt = CCOptions{KeyStart: strconv.Itoa(invkQueryObject.CCOptions.KeyStart), PayLoadMin: strconv.Itoa(invkQueryObject.CCOptions.PayLoadMin), PayLoadMax: strconv.Itoa(invkQueryObject.CCOptions.PayLoadMax)}
	i.EventOpt = EventOptions{Type: invkQueryObject.EventOptions.Type, Listener: invkQueryObject.EventOptions.Listener, TimeOut: strconv.Itoa(invkQueryObject.EventOptions.TimeOut)}
	i.ConnProfilePath = paths.GetConnProfilePathForOrg(orgName, organizations)
	invokeParams["move"] = Parameters{Fcn: "invoke", Args: strings.Split(invkQueryObject.Args, ",")}
	if action == "Query"{
		invokeParams["query"] = Parameters{Fcn: "invoke", Args: strings.Split(invkQueryObject.Args, ",")}
	}
	i.Parameters = invokeParams
	for key := range invkQueryObject.TxnOptions {
		mode := invkQueryObject.TxnOptions[key].Mode
		options := invkQueryObject.TxnOptions[key].Options
		i.TransMode = mode
		switch mode {
		case "constant":
			i.ConstOpt = ConstantOptions{RecHist: "HIST", ConstFreq: strconv.Itoa(options.ConstFreq), DevFreq: strconv.Itoa(options.DevFreq)}
		case "burst":
			i.BurstOpt = BurstOptions{BurstFreq0: strconv.Itoa(options.BurstFreq0), BurstDur0: strconv.Itoa(options.BurstDur0), BurstFreq1: strconv.Itoa(options.BurstFreq1), BurstDur1: strconv.Itoa(options.BurstDur1)}
		case "mix":
			i.MixOpt = MixOptions{MixFreq: strconv.Itoa(options.MixFreq)}
		}
		InvokeQueryObjects = append(InvokeQueryObjects, i)
	}
	return InvokeQueryObjects
}

func (i InvokeQueryObject) invokeTransactions(InvokeQueryObjects []InvokeQueryObject) error {

	var err error
	var jsonObject []byte
	pteMainPath := paths.PTEPath()
	for key := range InvokeQueryObjects {
		jsonObject, err = json.Marshal(InvokeQueryObjects[key])
		if err != nil {
			return err
		}
		startTime := fmt.Sprintf("%s", time.Now())
		args := []string{pteMainPath, strconv.Itoa(key), string(jsonObject), startTime}
		_, err = networkclient.ExecuteCommand("node", args, true)
		if err != nil {
			return err
		}
	}
	return err
}

//     FailoverOpt struct {
//         Method string `json:"method,omitempty"`
//         List   string `json:"list,omitempty"`
//     } `json:"failoverOpt,omitempty"`
//     InvokeCheckOpt struct {
//         Peers        string `json:"peers,omitempty"`
//         Transactions string `json:"transactions,omitempty"`
//         TxNum        string `json:"txNum,omitempty"`
//     } `json:"invokeCheckOpt,omitempty"`
//     OrdererOpt struct {
//         Method    string `json:"method,omitempty"`
//         NOrderers string `json:"nOrderers,omitempty"`
//     } `json:"ordererOpt,omitempty"`
//     TimeoutOpt struct {
//         PreConfig   string `json:"preConfig,omitempty"`
//         Request     string `json:"request,omitempty"`
//         GrpcTimeout string `json:"grpcTimeout,omitempty"`
//     } `json:"timeoutOpt,omitempty"`
// }
