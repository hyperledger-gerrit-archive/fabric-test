package operations

import (
	"encoding/json"
	"fmt"
	"path/filepath"
	"strconv"
	"github.com/hyperledger/fabric-test/tools/operator/paths"
	"github.com/hyperledger/fabric-test/tools/operator/networkclient"
	"github.com/hyperledger/fabric-test/tools/operator/testclient/helper"
)

//AnchorPeerUpdateObject --
type AnchorPeerUpdateObject struct {
    TransType       string         `json:"transType,omitempty"`
    TLS             string         `json:"TLS,omitempty"`
    ChannelOpt      ChannelOptions `json:"channelOpt,omitempty"`
    ConnProfilePath string         `json:"ConnProfilePath,omitempty"`
}

//AnchorPeerUpdate -- To create a channel
func (a AnchorPeerUpdateObject) AnchorPeerUpdate(config helper.Config) error {

	var err error
	var anchorPeerUpdateObjects, anchorPeerObjects []AnchorPeerUpdateObject
	tls := config.TLS
	switch tls {
	case "true":
		tls = "enabled"
	case "false":
		tls = "disabled"
	case "mutual":
		tls = "clientauth"
	}
	for i := 0; i < len(config.AnchorPeerUpdate); i++ {
		anchorPeerObjects = a.generateAnchorPeerUpdateObjects(config.AnchorPeerUpdate[i], config.Organizations, tls, config.AnchorPeerUpdate[i].AnchorPeerTxPath)
		if len(anchorPeerObjects) > 0 {
			anchorPeerUpdateObjects = append(anchorPeerUpdateObjects, anchorPeerObjects...)
		}
	}
	err = a.anchorPeerUpdate(anchorPeerUpdateObjects)
	if err != nil {
		return err
	}
	return nil
}

func (a AnchorPeerUpdateObject) generateAnchorPeerUpdateObjects(anchorPeer helper.AnchorPeerUpdate, organizations []helper.Organization, tls, anchorPeerTxPath string) []AnchorPeerUpdateObject {

	var connProfilePath string
	var anchorPeerObjects []AnchorPeerUpdateObject
	for i := 0; i < len(organizations); i++ {
		if organizations[i].Name == anchorPeer.Organizations {
			connProfilePath = organizations[i].ConnProfilePath
		}
	}
	if anchorPeer.ChannelPrefix != "" && anchorPeer.NumChannels > 0 {
		anchorPeerObjects = a.createAnchorPeerObjectIfChanPrefix(anchorPeer, tls, connProfilePath, anchorPeerTxPath)
		return anchorPeerObjects
	}
	a = AnchorPeerUpdateObject{TransType: "Channel", TLS: tls, ConnProfilePath: connProfilePath}
	channelOpt := ChannelOptions{Name: anchorPeer.ChannelName, ChannelTX: anchorPeerTxPath, Action: "update", OrgName: []string{anchorPeer.Organizations}}
	a.ChannelOpt = channelOpt
	anchorPeerObjects = append(anchorPeerObjects, a)
	return anchorPeerObjects
}

func (a AnchorPeerUpdateObject) createAnchorPeerObjectIfChanPrefix(anchorPeer helper.AnchorPeerUpdate, tls, connProfilePath, anchorPeerTxPath string) []AnchorPeerUpdateObject{

	var anchorPeerObjects []AnchorPeerUpdateObject
	var channelName, anchopPeerTxPath string
	a = AnchorPeerUpdateObject{TransType: "Channel", TLS: tls, ConnProfilePath: connProfilePath}
	for j := 0; j < anchorPeer.NumChannels; j++ {
		channelName = fmt.Sprintf("%s%s", anchorPeer.ChannelPrefix, strconv.Itoa(j))
		anchopPeerTxPath = filepath.Join(anchorPeerTxPath, fmt.Sprintf("%s%sanchor.tx", channelName, anchorPeer.Organizations))
		channelOpt := ChannelOptions{Name: channelName, ChannelTX: anchopPeerTxPath, Action: "update", OrgName: []string{anchorPeer.Organizations}}
		a.ChannelOpt = channelOpt
		anchorPeerObjects = append(anchorPeerObjects, a)
	}
	return anchorPeerObjects
}

func (a AnchorPeerUpdateObject) anchorPeerUpdate(anchorPeerObjects []AnchorPeerUpdateObject) error {

	var err error
	var jsonObject []byte
	for i := 0; i < len(anchorPeerObjects); i++ {
		jsonObject, err = json.Marshal(anchorPeerObjects[i])
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
