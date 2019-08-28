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
	InstantiateCC     []InstantiateCC    `yaml:"instantiateChaincode,omitempty"`
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
	ChainCodeName    string `yaml:"chaincodeName,omitempty"`
	ChainCodeVersion string `yaml:"ccVersion,omitempty"`
	ChainCodePath    string `yaml:"chaincodePath,omitempty"`
	Organizations    string `yaml:"organizations,omitempty"`
	Language         string `yaml:"language,omitempty"`
	MetadataPath     string `yaml:"metadataPath,omitempty"`
}

//InstantiateCC --
type InstantiateCC struct {
	ChannelName       string `yaml:"channelName,omitempty"`
	ChainCodeName     string `yaml:"chaincodeName,omitempty"`
	ChainCodeVersion  string `yaml:"ccVersion,omitempty"`
	ChainCodePath     string `yaml:"chaincodePath,omitempty"`
	Organizations     string `yaml:"organizations,omitempty"`
	EndorsementPolicy string `yaml:"endorsementPolicy,omitempty"`
	ChannelPrefix     string `yaml:"channelPrefix,omitempty"`
	NumChannels       string `yaml:"numChannels,omitempty"`
	CollectionPath    string `yaml:"collectionPath,omitempty"`
	Language          string `yaml:"language,omitempty"`
	TimeOutOpt        struct {
		PreConfig string `yaml:"preConfig,omitempty"`
		Request   string `yaml:"request,omitempty"`
	} `yaml:"timeoutOpt,omitempty"`
}

//Invoke --
type Invoke struct {
	ChannelName   string `yaml:"channelName,omitempty"`
	TargetPeers   string `yaml:"targetPeers,omitempty"`
	NProcPerOrg   int    `yaml:"nProcPerOrg,omitempty"`
	NRequest      int    `yaml:"nRequest,omitempty"`
	RunDuration   int    `yaml:"runDur,omitempty"`
	Organizations string `yaml:"organizations,omitempty"`
	TxnOptions    []struct {
		Mode    string `yaml:"mode,omitempty"`
		Options string `yaml:"options,omitempty"`
	} `yaml:"txnOpts,omitempty"`
	QueryCheck   string `yaml:"queryCheck,omitempty"`
	EventOptions struct {
		Type     string `yaml:"type,omitempty"`
		Listener string `yaml:"listener,omitempty"`
		Timeout  string `yaml:"timeout,omitempty"`
	} `yaml:"eventOpt,omitempty"`
	CCOptions struct {
		CCType     string `yaml:"ccType,omitempty"`
		KeyStart   int    `yaml:"keyStart,omitempty"`
		PayLoadMin string `yaml:"payLoadMin,omitempty"`
		PayLoadMax string `yaml:"payLoadMax,omitempty"`
	} `yaml:"ccOpt,omitempty"`
	MoveArgs string `yaml:"moveArgs,omitempty"`
}

//Query --
type Query struct {
	ChannelName   string `yaml:"channelName,omitempty"`
	TargetPeers   string `yaml:"targetPeers,omitempty"`
	NProcPerOrg   int    `yaml:"nProcPerOrg,omitempty"`
	NRequest      int    `yaml:"nRequest,omitempty"`
	RunDuration   int    `yaml:"runDur,omitempty"`
	Organizations string `yaml:"organizations,omitempty"`
	CCOptions     struct {
		CCType   string `yaml:"ccType,omitempty"`
		KeyStart int    `yaml:"keyStart,omitempty"`
	} `yaml:"ccOpt,omitempty"`
	QueryArgs string `yaml:"queryArgs,omitempty"`
}
