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
	}
	for i := 0; i < len(config.AnchorPeerUpdate); i++ {
		anchorPeerObjects, err = a.generateAnchorPeerUpdateObjects(config.AnchorPeerUpdate[i], config.Organizations, tls, config.AnchorPeerUpdate[i].AnchorPeerTxPath)
		if err != nil {
			return err
		}
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

func (a AnchorPeerUpdateObject) generateAnchorPeerUpdateObjects(anchorPeer helper.AnchorPeerUpdate, organizations []helper.Organization, TLS, channelTx string) ([]AnchorPeerUpdateObject, error) {

	var connProfilePath, channelName, anchopPeerTxPath string
	var anchorPeerObjects []AnchorPeerUpdateObject
	for i := 0; i < len(organizations); i++ {
		if organizations[i].Name == anchorPeer.Organizations {
			connProfilePath = organizations[i].ConnProfilePath
		}
	}
	a = AnchorPeerUpdateObject{TransType: "Channel", TLS: TLS, ConnProfilePath: connProfilePath}
	channelOpt := ChannelOptions{Name: anchorPeer.ChannelName, ChannelTX: channelTx, Action: "update", OrgName: []string{anchorPeer.Organizations}}
	a.ChannelOpt = channelOpt
	if anchorPeer.ChannelPrefix != "" && anchorPeer.NumChannels > 0 {
		for j := 0; j < anchorPeer.NumChannels; j++ {
            channelName = fmt.Sprintf("%s%s", anchorPeer.ChannelPrefix, strconv.Itoa(j))
            anchopPeerTxPath = filepath.Join(channelTx, fmt.Sprintf("%s%sanchor.tx", channelName, anchorPeer.Organizations))
			channelOpt := ChannelOptions{Name: channelName, ChannelTX: anchopPeerTxPath, Action: "update", OrgName: []string{anchorPeer.Organizations}}
			a.ChannelOpt = channelOpt
            anchorPeerObjects = append(anchorPeerObjects, a)
		}
	} else {
		anchorPeerObjects = append(anchorPeerObjects, a)
	}
	return anchorPeerObjects, nil
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
