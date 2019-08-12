package client

import (
	"fmt"

	"github.com/hyperledger/fabric-test/tools/operator/helper"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
)

//GenerateChannelTransaction - to generate channel transactions
func GenerateChannelTransaction(input networkspec.Config, configtxPath string) error {

	outputPath := helper.ChannelArtifactsDir(input.ArtifactsLocation)
	configtxgen := Configtxgen{Config: configtxPath, OutputPath: outputPath}

	for i := 0; i < input.NumChannels; i++ {
		channelName := fmt.Sprintf("testorgschannel%d", i)
		_, err := ExecuteCommand("configtxgen", configtxgen.ChanTxnArgs(channelName), true)
		if err != nil {
			return err
		}

		for j := 0; j < len(input.PeerOrganizations); j++ {
			_, err := ExecuteCommand("configtxgen", configtxgen.AnchorPeer(channelName, input.PeerOrganizations[j].Name), true)
			if err != nil {
				return err
			}
		}
	}
	return nil
}
