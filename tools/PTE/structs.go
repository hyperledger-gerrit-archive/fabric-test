package main

type Invoke struct {
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
	*Operations
}

type Operations struct {
	ChaincodeID  string `json:"chaincodeID,omitempty"`
	ChaincodeVer string `json:"chaincodeVer,omitempty"`
	TransType    string `json:"transType,omitempty"`
	TLS          string `json:"TLS,omitempty"`
	ChannelOpt   struct {
		Name      string   `json:"name,omitempty"`
		Action    string   `json:"action,omitempty"`
		ChannelTX string   `json:"channelTX,omitempty"`
		OrgName   []string `json:"orgName,omitempty"`
	} `json:"channelOpt,omitempty"`
	Deploy struct {
		ChaincodePath string   `json:"chaincodePath,omitempty"`
		MetadataPath  string   `json:"metadataPath,omitempty"`
		Language      string   `json:"language,omitempty"`
		Fcn           string   `json:"fcn,omitempty"`
		Args          []string `json:"args,omitempty"`
	} `json:"deploy,omitempty"`
	ConnProfilePath string `json:"ConnProfilePath,omitempty"`
}

type Config struct {
	ArtifactsLocation string `yaml:"artifacts_location,omitempty"`
	TLS               string `yaml:"TLS,omitempty"`
	Chaincode         struct {
		ChaincodeID   string   `yaml:"chaincodeVer,omitempty"`
		ChaincodeVer  string   `yaml:"chaincodeVer,omitempty"`
		ChaincodePath string   `yaml:"chaincodePath,omitempty"`
		MetadataPath  string   `yaml:"metadataPath,omitempty"`
		Language      string   `yaml:"language,omitempty"`
		Fcn           string   `yaml:"fcn,omitempty"`
		Args          []string `yaml:"args,omitempty"`
	} `yaml:"chaincode,omitempty"`
}
