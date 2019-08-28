package helpers

import (
    "encoding/json"
    "fmt"
    "path/filepath"
    "strconv"
	"github.com/hyperledger/fabric-test/tools/operator/logger"
    "github.com/hyperledger/fabric-test/tools/PTE/go/helper"
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
    }
    for i := 0; i < len(config.CreateChannel); i++ {
        channelObjects, err = c.generateCreateChannelObjects(config.CreateChannel[i], config.Organizations, tls, config.CreateChannel[i].ChannelTxPath)
        if err != nil {
            return err
        }
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

func (c CreateChannelObject) generateCreateChannelObjects(channel helper.CreateChannel, organizations []helper.Organization, TLS, channelTx string) ([]CreateChannelObject, error) {

    var connProfilePath, channelName, channelTxPath string
    var channelObjects []CreateChannelObject
    for i := 0; i < len(organizations); i++ {
        if organizations[i].Name == channel.Organizations {
            connProfilePath = organizations[i].ConnProfilePath
        }
    }
    c = CreateChannelObject{TransType: "Channel", TLS: TLS, ConnProfilePath: connProfilePath}
    channelOpt := ChannelOptions{Name: channel.ChannelName, ChannelTX: channelTx, Action: "create", OrgName: []string{channel.Organizations}}
    c.ChannelOpt = channelOpt
    if channel.ChannelPrefix != "" && channel.NumChannels > 0 {
        for j := 0; j < channel.NumChannels; j++ {
            channelName = fmt.Sprintf("%s%s", channel.ChannelPrefix, strconv.Itoa(j))
            channelTxPath = filepath.Join(channelTx, fmt.Sprintf("%s.tx", channelName))
            channelOpt := ChannelOptions{Name: channelName, ChannelTX: channelTxPath, Action: "create", OrgName: []string{channel.Organizations}}
            c.ChannelOpt = channelOpt
            channelObjects = append(channelObjects, c)
        }
    } else {
        channelObjects = append(channelObjects, c)
    }
    return channelObjects, nil
}

func (c CreateChannelObject) createChannel(createChannelObjects []CreateChannelObject) error {

    var err error
    var jsonObject []byte
    fmt.Println("inside createchannel function")
    for i := 0; i < len(createChannelObjects); i++ {
        jsonObject, err = json.Marshal(createChannelObjects[i])
        if err != nil {
            return err
        }
        _, err = helper.ExecuteCommand("node", []string{"../pte-main.js", string(jsonObject)}, true)
        if err != nil {
            return err
        }
    }
    return nil
}