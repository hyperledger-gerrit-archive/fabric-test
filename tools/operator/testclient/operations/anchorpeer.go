package operations

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/hyperledger/fabric-test/tools/operator/networkclient"
	"github.com/hyperledger/fabric-test/tools/operator/paths"
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
func (a AnchorPeerUpdateObject) AnchorPeerUpdate(config helper.Config, tls string) error {

	var err error
	var anchorPeerUpdateObjects, anchorPeerObjects []AnchorPeerUpdateObject
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

	var anchorPeerObjects []AnchorPeerUpdateObject
	if anchorPeer.ChannelPrefix != "" && anchorPeer.NumChannels > 0 {
		anchorPeerObjects = a.createAnchorPeerObjectIfChanPrefix(anchorPeer, organizations, tls)
		return anchorPeerObjects
	}
	orgNames := strings.Split(anchorPeer.Organizations, ",")
	anchorPeerObjects = a.createAnchorPeerUpdateObjects(orgNames, anchorPeer.ChannelName, anchorPeer.AnchorPeerTxPath, tls, organizations)
	return anchorPeerObjects
}

func (a AnchorPeerUpdateObject) createAnchorPeerUpdateObjects(orgNames []string, channelName, anchopPeerTxPath, tls string, organizations []helper.Organization) []AnchorPeerUpdateObject {

	var anchorPeerUpdateObjects []AnchorPeerUpdateObject
	var channelOpt ChannelOptions
	for _, orgName := range orgNames {
		orgName = strings.TrimSpace(orgName)
		channelOpt = ChannelOptions{Name: channelName, Action: "update", OrgName: []string{orgName}, ChannelTX: anchopPeerTxPath}
		a = AnchorPeerUpdateObject{TransType: "Channel", TLS: tls, ConnProfilePath: paths.GetConnProfilePathForOrg(orgName, organizations), ChannelOpt: channelOpt}
		anchorPeerUpdateObjects = append(anchorPeerUpdateObjects, a)
	}
	return anchorPeerUpdateObjects
}

func (a AnchorPeerUpdateObject) createAnchorPeerObjectIfChanPrefix(anchorPeer helper.AnchorPeerUpdate, organizations []helper.Organization, tls string) []AnchorPeerUpdateObject {

	var anchorPeerUpdateObjects []AnchorPeerUpdateObject
	var channelName, anchopPeerTxPath string
	for j := 0; j < anchorPeer.NumChannels; j++ {
		channelName = fmt.Sprintf("%s%s", anchorPeer.ChannelPrefix, strconv.Itoa(j))
		anchopPeerTxPath = paths.JoinPath(anchorPeer.AnchorPeerTxPath, fmt.Sprintf("%s%sanchor.tx", channelName, anchorPeer.Organizations))
		orgNames := strings.Split(anchorPeer.Organizations, ",")
		anchorPeerObjects := a.createAnchorPeerUpdateObjects(orgNames, channelName, anchopPeerTxPath, tls, organizations)
		anchorPeerUpdateObjects = append(anchorPeerUpdateObjects, anchorPeerObjects...)
	}
	return anchorPeerUpdateObjects
}

func (a AnchorPeerUpdateObject) anchorPeerUpdate(anchorPeerObjects []AnchorPeerUpdateObject) error {

	var err error
	var jsonObject []byte
	pteMainPath := paths.PTEPath()
	for i := 0; i < len(anchorPeerObjects); i++ {
		jsonObject, err = json.Marshal(anchorPeerObjects[i])
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
