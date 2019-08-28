package helpers

import (
	"fabric-test/fabric/common/mocks/config"
	"fmt"

	"github.com/hyperledger/fabric-test/tools/PTE/go/pte"
)

//CreateChannelObject --
type CreateChannelObject struct {
	TransType  string `json:"transType,omitempty"`
	TLS        string `json:"TLS,omitempty"`
	ChannelOpt struct {
		Name      string   `json:"name,omitempty"`
		ChannelTX string   `json:"channelTX,omitempty"`
		Action    string   `json:"action,omitempty"`
		OrgName   []string `json:"orgName,omitempty"`
	} `json:"channelOpt,omitempty"`
	ConnProfilePath string `json:"ConnProfilePath,omitempty"`
}

//CreateChannels -- To create a channel
func (c CreateChannelObject) CreateChannels(config pte.Config) error {

	var err error
	var createChannelObjects, channelObjects []CreateChannelObject
	for i := 0; i < len(config.CreateChannel); i++ {
		channelObjects, err = generateCreateChannelObjects(config.CreateChannel[i], config)
		if err != nil {

		}
		if len(channelObjects) > 0 {
			createChannelObjects = appen(createChannelObjects, channelObjects...)
		}
	}
	err = c.createChannel(createChannelObjects)
	if err != nil {

	}
	err = pte.ExecuteCommand("node", "node/pte-main.js", createChannelObject)
	if err != nil {
		return fmt.Errorf("%v", err)
	}
	return nil
}

func (c CreateChannelObject) generateCreateChannelObjects(channel config.Channel, organizations []pte.Organization, TLS, channelTx string) ([]CreateChannelObject, error) {

	var connProfilePath string
	for orgName, connProfile := range organizations {
		if channel.Organizations == orgName {
			connProfilePath = connProfile
		}
	}
	c = CreateChannelObject{TransType: "Channel", TLS: TLS, ConnProfilePath: connProfilePath}
	channelOpt := c.ChannelOpt{Name: channel.ChannelName, ChannelTX: channelTx, Action: "create", OrgName: []string{channel.Organizations}}
	c.ChannelOpt = channelOpt
	fmt.Println(c)
	return []CreateChannelObject{c}, nil
}

func (c CreateChannelObject) createChannel(createChannelObjects []CreateChannelObject) error {

	for i := 0; i < len(createChannelObjects); i++ {
		err = pte.ExecuteCommand("node", "../pte-main.js", createChannelObjects[i])
		if err != nil {
			return err
		}
	}
	return nil
}
