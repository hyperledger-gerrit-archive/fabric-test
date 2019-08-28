package operations

import (
	"encoding/json"
	"fmt"
	"path/filepath"
	"strconv"

	"github.com/hyperledger/fabric-test/tools/operator/networkclient"
	"github.com/hyperledger/fabric-test/tools/operator/paths"
	"github.com/hyperledger/fabric-test/tools/operator/testclient/helper"
)

//CreateChannelObject --
type CreateChannelObject struct {
	TransType       string         `json:"transType,omitempty"`
	TLS             string         `json:"TLS,omitempty"`
	ChannelOpt      ChannelOptions `json:"channelOpt,omitempty"`
	ConnProfilePath string         `json:"ConnProfilePath,omitempty"`
}

type ChannelOptions struct {
	Name      string   `json:"name,omitempty"`
	ChannelTX string   `json:"channelTX,omitempty"`
	Action    string   `json:"action,omitempty"`
	OrgName   []string `json:"orgName,omitempty"`
}

//CreateChannels -- To create a channel
func (c CreateChannelObject) CreateChannels(config helper.Config) error {

	var err error
	var createChannelObjects, channelObjects []CreateChannelObject
	tls := config.TLS
	switch tls {
	case "true":
		tls = "enabled"
	case "false":
        tls = "disabled"
    case "mutual";
        tls = "clientauth"
	}
	for i := 0; i < len(config.CreateChannel); i++ {
		channelObjects = c.generateCreateChannelObjects(config.CreateChannel[i], config.Organizations, tls, config.CreateChannel[i].ChannelTxPath)
		if len(channelObjects) > 0 {
			createChannelObjects = append(createChannelObjects, channelObjects...)
		}
	}
	err = c.createChannel(createChannelObjects)
	if err != nil {
		return err
	}
	return nil
}

func (c CreateChannelObject) generateCreateChannelObjects(channel helper.Channel, organizations []helper.Organization, tls, channelTx string) []CreateChannelObject {

	var connProfilePath string
	var channelObjects []CreateChannelObject
	for i := 0; i < len(organizations); i++ {
		if organizations[i].Name == channel.Organizations {
			connProfilePath = organizations[i].ConnProfilePath
		}
	}
	if channel.ChannelPrefix != "" && channel.NumChannels > 0 {
		channelObjects = c.createChannelObjectIfChanPrefix(channel, tls, channelTx, connProfilePath)
		return channelObjects
	}
	c = CreateChannelObject{TransType: "Channel", TLS: tls, ConnProfilePath: connProfilePath}
	channelOpt := ChannelOptions{Name: channel.ChannelName, ChannelTX: channelTx, Action: "create", OrgName: []string{channel.Organizations}}
	c.ChannelOpt = channelOpt
	channelObjects = append(channelObjects, c)
	return channelObjects
}

func (c CreateChannelObject) createChannelObjectIfChanPrefix(channel helper.Channel, tls, channelTx, connProfilePath string) []CreateChannelObject {

	var channelObjects []CreateChannelObject
	var channelTxPath, channelName string
	c = CreateChannelObject{TransType: "Channel", TLS: tls, ConnProfilePath: connProfilePath}
	for j := 0; j < channel.NumChannels; j++ {
		channelName = fmt.Sprintf("%s%s", channel.ChannelPrefix, strconv.Itoa(j))
		channelTxPath = filepath.Join(channelTx, fmt.Sprintf("%s.tx", channelName))
		channelOpt := ChannelOptions{Name: channelName, ChannelTX: channelTxPath, Action: "create", OrgName: []string{channel.Organizations}}
		c.ChannelOpt = channelOpt
		channelObjects = append(channelObjects, c)
	}
	return channelObjects
}

func (c CreateChannelObject) createChannel(createChannelObjects []CreateChannelObject) error {

	var err error
	var jsonObject []byte
	for i := 0; i < len(createChannelObjects); i++ {
		jsonObject, err = json.Marshal(createChannelObjects[i])
		if err != nil {
			return err
		}
		pteMainPath := paths.PTEPath()
		_, err = networkclient.ExecuteCommand("node", []string{pteMainPath, string(jsonObject)}, true)
		if err != nil {
			return err
		}
	}
	return nil
}
