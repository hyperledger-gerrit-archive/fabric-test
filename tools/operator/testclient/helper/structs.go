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

//InvokeTranscations --
type InvokeTranscations struct {
	LogLevel        string `json:"logLevel,omitempty"`
	InvokeCheck     string `json:"invokeCheck,omitempty"`
	TransMode       string `json:"transMode,omitempty"`
	TransType       string `json:"transType,omitempty"`
	InvokeType      string `json:"invokeType,omitempty"`
	TargetPeers     string `json:"targetPeers,omitempty"`
	PeerFailover    string `json:"peerFailover,omitempty"`
	OrdererFailover string `json:"ordererFailover,omitempty"`

	NProcPerOrg string `json:"nProcPerOrg,omitempty"`
	NRequest    string `json:"nRequest,omitempty"`
	RunDur      string `json:"runDur,omitempty"`
	BurstOpt    struct {
		BurstFreq []string `json:"burstFreq,omitempty"`
		BurstDur  []string `json:"burstDur,omitempty"`
	} `json:"burstOpt,omitempty"`
	MixOpt struct {
		MixQuery string `json:"mixQuery,omitempty"`
		MixFreq  string `json:"mixFreq,omitempty"`
	} `json:"mixOpt,omitempty"`
	ConstantOpt struct {
		RecHist   string `json:"recHist,omitempty"`
		ConstFreq string `json:"constFreq,omitempty"`
		DevFreq   string `json:"devFreq,omitempty"`
	} `json:"constantOpt,omitempty"`
	ListOpt struct {
		Org1 []string `json:"org1,omitempty"`
		Org2 []string `json:"org2,omitempty"`
	} `json:"listOpt,omitempty"`
	EventOpt struct {
		Type     string `json:"type,omitempty"`
		Listener string `json:"listener,omitempty"`
		Timeout  string `json:"timeout,omitempty"`
	} `json:"eventOpt,omitempty"`
	FailoverOpt struct {
		Method string `json:"method,omitempty"`
		List   string `json:"list,omitempty"`
	} `json:"failoverOpt,omitempty"`
	InvokeCheckOpt struct {
		Peers        string `json:"peers,omitempty"`
		Transactions string `json:"transactions,omitempty"`
		TxNum        string `json:"txNum,omitempty"`
	} `json:"invokeCheckOpt,omitempty"`
	OrdererOpt struct {
		Method    string `json:"method,omitempty"`
		NOrderers string `json:"nOrderers,omitempty"`
	} `json:"ordererOpt,omitempty"`
	TimeoutOpt struct {
		PreConfig   string `json:"preConfig,omitempty"`
		Request     string `json:"request,omitempty"`
		GrpcTimeout string `json:"grpcTimeout,omitempty"`
	} `json:"timeoutOpt,omitempty"`
	*ChainCodeObject
}
