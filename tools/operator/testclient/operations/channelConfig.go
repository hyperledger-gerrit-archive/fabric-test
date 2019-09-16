package operations

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/hyperledger/fabric-test/tools/operator/networkclient"
	"github.com/hyperledger/fabric-test/tools/operator/paths"
	"github.com/hyperledger/fabric-test/tools/operator/testclient/inputStructs"
)

//ChannelUIObject --
type ChannelUIObject struct {
	TransType       string         `json:"transType,omitempty"`
	TLS             string         `json:"TLS,omitempty"`
	ChannelOpt      ChannelOptions `json:"channelOpt,omitempty"`
	ConnProfilePath string         `json:"ConnProfilePath,omitempty"`
}

//ChannelOptions --
type ChannelOptions struct {
	Name      string   `json:"name,omitempty"`
	ChannelTX string   `json:"channelTX,omitempty"`
	Action    string   `json:"action,omitempty"`
	OrgName   []string `json:"orgName,omitempty"`
}

//ChannelConfigs -- To create channel objects based on create, join and anchorpeer and perform the channel configs
func (c ChannelUIObject) ChannelConfigs(config inputStructs.Config, tls, action string) error {

	var err error
	var channelUIObjects, channelObjects []ChannelUIObject
	var configObjects []inputStructs.Channel
	switch action {
	case "create":
		configObjects = config.CreateChannel
	case "join":
		configObjects = config.JoinChannel
	case "anchorpeer":
		configObjects = config.AnchorPeerUpdate
	}
	for i := 0; i < len(configObjects); i++ {
		channelObjects = c.generateChannelUIObjects(configObjects[i], config.Organizations, tls, action)
		if len(channelObjects) > 0 {
			channelUIObjects = append(channelUIObjects, channelObjects...)
		}
	}
	err = c.doChannelAction(channelUIObjects)
	if err != nil {
		return err
	}
	return nil
}

func (c ChannelUIObject) generateChannelUIObjects(channel inputStructs.Channel, organizations []inputStructs.Organization, tls, action string) []ChannelUIObject {

	var channelObjects []ChannelUIObject
	if channel.ChannelPrefix != "" && channel.NumChannels > 0 {
		channelObjects = c.createChannelObjectIfChanPrefix(channel, organizations, tls, action)
		return channelObjects
	}
	orgNames := strings.Split(channel.Organizations, ",")
	channelObjects = c.createChannelConfigObjects(orgNames, channel.ChannelName, channel.ChannelTxPath, channel.AnchorPeerTxPath, tls, action, organizations)
	return channelObjects
}

func (c ChannelUIObject) createChannelConfigObjects(orgNames []string, channelName, channelTxPath, anchorPeerTxPath, tls, action string, organizations []inputStructs.Organization) []ChannelUIObject {

	var channelObjects []ChannelUIObject
	var channelOpt ChannelOptions
	if action != "join" && len(orgNames) > 1{
		orgNames = []string{orgNames[0]}
	}
	for _, orgName := range orgNames {
		orgName = strings.TrimSpace(orgName)
		if action == "anchorpeer" {
			action = "update"
			channelTxPath = anchorPeerTxPath
		}
		channelOpt = ChannelOptions{Name: channelName, Action: action, OrgName: []string{orgName}, ChannelTX: channelTxPath}
		c = ChannelUIObject{TransType: "Channel", TLS: tls, ConnProfilePath: paths.GetConnProfilePathForOrg(orgName, organizations), ChannelOpt: channelOpt}
		channelObjects = append(channelObjects, c)
	}
	return channelObjects
}

func (c ChannelUIObject) createChannelObjectIfChanPrefix(channel inputStructs.Channel, organizations []inputStructs.Organization, tls, action string) []ChannelUIObject {

	var channelUIObjects []ChannelUIObject
	var channelTxPath, anchopPeerTxPath, channelName string
	if action != "anchorpeer" {
		for j := 0; j < channel.NumChannels; j++ {
			channelName = fmt.Sprintf("%s%s", channel.ChannelPrefix, strconv.Itoa(j))
			channelTxPath = paths.JoinPath(channel.ChannelTxPath, fmt.Sprintf("%s.tx", channelName))
			orgNames := strings.Split(channel.Organizations, ",")
			channelobjects := c.createChannelConfigObjects(orgNames, channelName, channelTxPath, anchopPeerTxPath, tls, action, organizations)
			channelUIObjects = append(channelUIObjects, channelobjects...)
		}
		return channelUIObjects
	}
	for j := 0; j < channel.NumChannels; j++ {
		channelName = fmt.Sprintf("%s%s", channel.ChannelPrefix, strconv.Itoa(j))
		anchopPeerTxPath = paths.JoinPath(channel.AnchorPeerTxPath, fmt.Sprintf("%s%sanchor.tx", channelName, channel.Organizations))
		orgNames := strings.Split(channel.Organizations, ",")
		anchorPeerObjects := c.createChannelConfigObjects(orgNames, channelName, channelTxPath, anchopPeerTxPath, tls, action, organizations)
		channelUIObjects = append(channelUIObjects, anchorPeerObjects...)
	}
	return channelUIObjects
}

func (c ChannelUIObject) doChannelAction(channelUIObjects []ChannelUIObject) error {

	var err error
	var jsonObject []byte
	pteMainPath := paths.PTEPath()
	for i := 0; i < len(channelUIObjects); i++ {
		jsonObject, err = json.Marshal(channelUIObjects[i])
		if err != nil {
			return err
		}
		startTime := fmt.Sprintf("%s", time.Now())
		args := []string{pteMainPath, strconv.Itoa(i), string(jsonObject), startTime}
		_, err = networkclient.ExecuteCommand("node", args, true)
		if err != nil {
			return err
		}
	}
	return nil
}
