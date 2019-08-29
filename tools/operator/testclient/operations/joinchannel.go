package operations

import (
	"encoding/json"
	"fmt"
	"strconv"
	"time"
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
func (j JoinChannelObject) JoinChannels(config helper.Config, tls) error {

	var err error
	var joinChannelObjects, channelObjects []JoinChannelObject
	for i := 0; i < len(config.JoinChannel); i++ {
		channelObjects = j.generateJoinChannelObjects(config.JoinChannel[i], config.Organizations, tls)
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

func (j JoinChannelObject) generateJoinChannelObjects(channel helper.Channel, organizations []helper.Organization, tls string) []JoinChannelObject {

	var channelObjects []JoinChannelObject

	if channel.ChannelPrefix != "" && channel.NumChannels > 0 {
		channelObjects = j.createChannelObjectIfChanPrefix(channel, organizations, tls)
		return channelObjects
	}
	orgNames := strings.Split(channel.Organizations, ",")
	channelObjects = j.createJoinChannelObjects(orgNames, channel.ChannelName, tls, channel, organizations)
	return channelObjects
}

func (j JoinChannelObject) getConnProfilePathForOrg(orgName string, organizations []helper.Organization) string {
	var connProfilePath string
	for i := 0; i < len(organizations); i++ {
		if organizations[i].Name == orgName {
			connProfilePath = organizations[i].ConnProfilePath
		}
	}
	return connProfilePath
}

func (j JoinChannelObject) createJoinChannelObjects(orgNames []string, channelName, tls string, channel helper.Channel, organizations []helper.Organization) []JoinChannelObject {

	var joinChannelObjects []JoinChannelObject
	var channelOpt ChannelOptions
	for _, orgName := range orgNames {
		orgName = strings.TrimSpace(orgName)
		channelOpt = ChannelOptions{Name: channelName, Action: "join", OrgName: []string{orgName}}
		j = JoinChannelObject{TransType: "Channel", TLS: tls, ConnProfilePath: j.getConnProfilePathForOrg(orgName, organizations), ChannelOpt: channelOpt}
		joinChannelObjects = append(joinChannelObjects, j)
	}
	return joinChannelObjects
}

func (j JoinChannelObject) createChannelObjectIfChanPrefix(channel helper.Channel, organizations []helper.Organization, tls string) []JoinChannelObject {

	var joinChannelObjects []JoinChannelObject
	var channelName string
	for i := 0; i < channel.NumChannels; i++ {
		channelName = fmt.Sprintf("%s%s", channel.ChannelPrefix, strconv.Itoa(i))
		orgNames := strings.Split(channel.Organizations, ",")
		channelObjects := j.createJoinChannelObjects(orgNames, channelName, tls, channel, organizations)
		joinChannelObjects = append(joinChannelObjects, channelObjects...)
	}
	return joinChannelObjects
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
		startTime := fmt.Sprintf("%s", time.Now())
		args := []string{pteMainPath, strconv.Itoa(i), string(jsonObject), startTime}
		_, err = networkclient.ExecuteCommand("node", args, true)
		if err != nil {
			return err
		}
	}
	return nil
}
