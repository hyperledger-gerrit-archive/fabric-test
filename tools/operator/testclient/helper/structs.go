package helper

//Config --
type Config struct {
	ArtifactsLocation string             `yaml:"artifacts_location,omitempty"`
	TLS               string             `yaml:"tls,omitempty"`
	Organizations     []Organization     `yaml:"organizations,omitempty"`
	CreateChannel     []Channel          `yaml:"createChannel,omitempty"`
	AnchorPeerUpdate  []AnchorPeerUpdate `yaml:"anchorPeerUpdate,omitempty"`
	JoinChannel       []Channel          `yaml:"joinChannel,omitempty"`
	InstallCC         []InstallCC        `yaml:"installChaincode,omitempty"`
}

//Channel --
type Channel struct {
	ChannelTxPath string `yaml:"channelTxPath,omitempty"`
	ChannelName   string `yaml:"channelName,omitempty"`
	Organizations string `yaml:"organizations,omitempty"`
	ChannelPrefix string `yaml:"channelPrefix,omitempty"`
	NumChannels   int    `yaml:"numChannels,omitempty"`
}

//AnchorPeerUpdate --
type AnchorPeerUpdate struct {
	AnchorPeerTxPath string `yaml:"anchorPeerUpdateTxPath,omitempty"`
	ChannelName      string `yaml:"channelName,omitempty"`
	Organizations    string `yaml:"organization,omitempty"`
	ChannelPrefix    string `yaml:"channelPrefix,omitempty"`
	NumChannels      int    `yaml:"numChannels,omitempty"`
}

//Organization --
type Organization struct {
	Name            string `yaml:"name,omitempty"`
	ConnProfilePath string `yaml:"connProfilePath,omitempty"`
}

//InstallCC --
type InstallCC struct {
	ChainCodeName    string `yaml:"chaincodeID,omitempty"`
	ChainCodeVersion string `yaml:"chaincodeVer,omitempty"`
	ChainCodePath    string `yaml:"chaincodePath,omitempty"`
	Organizations    string `yaml:"organizations,omitempty"`
	Language         string `yaml:"language,omitempty"`
	MetadataPath     string `yaml:"metadataPath,omitempty"`
}

//InstantiateCC --
type InstantiateCC struct {
	ChainCodeName     string `yaml:"chaincodeID,omitempty"`
	ChainCodeVersion  string `yaml:"chaincodeVer,omitempty"`
	ChainCodePath     string `yaml:"chaincodePath,omitempty"`
	Organizations     string `yaml:"organizations,omitempty"`
	EndorsementPolicy string `yaml:"endorsementPolicy,omitempty"`
	CollectionPath    string `yaml:"collectionPath,omitempty"`
	Language          string `yaml:"language,omitempty"`
	TimeOutOpt        struct {
		PreConfig string `yaml:"preConfig,omitempty"`
		Request   string `yaml:"request,omitempty"`
	} `yaml:"timeoutOpt,omitempty"`
}
