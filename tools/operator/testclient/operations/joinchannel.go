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

//JoinChannelObject --
type JoinChannelObject struct {
	TransType       string         `json:"transType,omitempty"`
	TLS             string         `json:"TLS,omitempty"`
	ChannelOpt      ChannelOptions `json:"channelOpt,omitempty"`
	ConnProfilePath string         `json:"ConnProfilePath,omitempty"`
}

//JoinChannels -- To join a channel
func (j JoinChannelObject) JoinChannels(config helper.Config) error {

	var err error
	var joinChannelObjects, channelObjects []JoinChannelObject
	tls := config.TLS
	switch tls {
	case "true":
		tls = "enabled"
	case "false":
		tls = "disabled"
	}
	for i := 0; i < len(config.JoinChannel); i++ {
		channelObjects, err = j.generateJoinChannelObjects(config.JoinChannel[i], config.Organizations, tls)
		if err != nil {
			return err
		}
		if len(channelObjects) > 0 {
			joinChannelObjects = append(joinChannelObjects, channelObjects...)
		}
	}
	err = j.joinChannel(joinChannelObjects)
	if err != nil {
		return err
	}
	return nil
}

func (j JoinChannelObject) generateJoinChannelObjects(channel helper.Channel, organizations []helper.Organization, TLS string) ([]JoinChannelObject, error) {

	var connProfilePath, channelName string
	var channelOpt ChannelOptions
	var channelObjects []JoinChannelObject
	var orgNames []string

	orgNames = strings.Split(channel.Organizations, ",")
	channelOpt = ChannelOptions{Name: channel.ChannelName, Action: "join"}
	for _, org := range orgNames {
		channelOpt.OrgName = append(channelOpt.OrgName, strings.TrimSpace(org))
	}
	for i := 0; i < len(organizations); i++ {
		if organizations[i].Name == orgNames[0] {
			connProfilePath = organizations[i].ConnProfilePath
		}
	}
	j = JoinChannelObject{TransType: "Channel", TLS: TLS, ConnProfilePath: connProfilePath}
	j.ChannelOpt = channelOpt
	if channel.ChannelPrefix != "" && channel.NumChannels > 0 {
		for index := 0; index < channel.NumChannels; index++ {
			channelName = fmt.Sprintf("%s%s", channel.ChannelPrefix, strconv.Itoa(index))
			channelOpt = ChannelOptions{Name: channelName, Action: "join"}
			orgNames = strings.Split(channel.Organizations, ",")
			for _, org := range orgNames {
				channelOpt.OrgName = append(channelOpt.OrgName, strings.TrimSpace(org))
			}
			j.ChannelOpt = channelOpt
			channelObjects = append(channelObjects, j)
		}
	} else {
		channelObjects = append(channelObjects, j)
	}
	return channelObjects, nil
}

func (j JoinChannelObject) joinChannel(joinChannelObjects []JoinChannelObject) error {

	var err error
	var jsonObject []byte
	for i := 0; i < len(joinChannelObjects); i++ {
		jsonObject, err = json.Marshal(joinChannelObjects[i])
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
