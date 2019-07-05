package nl

type NetworkLauncher struct{}

type Config struct {
    ArtifactsLocation    string                 `yaml:"certs_location,omitempty"`
    OrdererOrganizations []OrdererOrganizations `yaml:"orderer_organizations,omitempty"`
    PeerOrganizations    []PeerOrganizations    `yaml:"peer_organizations,omitempty"`
    NumChannels          int                    `yaml:"num_channels,omitempty"`
    K8s                  struct {
        DataPersistance bool   `yaml:"data_persistance,omitempty"`
        ServiceType     string `yaml:"service_type,omitempty"`
    } `yaml:"k8s,omitempty"`
}

type OrdererOrganizations struct {
    Name        string `yaml:"name,omitempty"`
    MspID       string `yaml:"msp_id,omitempty"`
    NumOrderers int    `yaml:"num_orderers,omitempty"`
    NumCa       int    `yaml:"num_ca,omitempty"`
}

type KafkaConfig struct {
    NumKafka             int `yaml:"num_kafka,omitempty"`
    NumKafkaReplications int `yaml:"num_kafka_replications,omitempty"`
    NumZookeepers        int `yaml:"num_zookeepers,omitempty"`
}

type PeerOrganizations struct {
    Name     string `yaml:"name,omitempty"`
    MspID    string `yaml:"msp_id,omitempty"`
    NumPeers int    `yaml:"num_peers,omitempty"`
    NumCa    int    `yaml:"num_ca,omitempty"`
}

type MSP struct {
    AdminCerts struct {
        AdminPem string `json:"admin_pem"`
    } `json:"admin_certs"`
    CACerts struct {
        CaPem string `json:"ca_pem"`
    } `json:"ca_certs"`
    TlsCaCerts struct {
        TlsPem string `json:"tls_pem"`
    } `json:"tls_ca"`
    SignCerts struct {
        OrdererPem string `json:"pem"`
    } `json:"sign_certs"`
    Keystore struct {
        PrivateKey string `json:"private_key"`
    } `json:"key_store"`
}

type TLS struct {
    CaCert     string `json:"ca_cert"`
    ServerCert string `json:"server_cert"`
    ServerKey  string `json:"server_key"`
}

type CA struct {
    Pem        string `json:"pem"`
    PrivateKey string `json:"private_key"`
}

type TlsCa struct {
    Pem        string `json:"pem"`
    PrivateKey string `json:"private_key"`
}

type Component struct {
    Msp   MSP   `json:"msp"`
    Tls   TLS   `json:"tls"`
    Ca    CA    `json:"ca"`
    Tlsca TlsCa `json:"tlsca"`
}

type Orderer struct {
    MSPID       string `yaml:"mspid"`
    Url         string `yaml:"url"`
    GrpcOptions struct {
        SslTarget string `yaml:"ssl-target-name-override"`
    } `yaml:"grpcOptions"`
    TlsCACerts struct {
        Path string `yaml:"path"`
    } `yaml:"tlsCACerts"`
    AdminPath string `yaml:"adminPath"`
}

type Peer struct {
    Url         string `yaml:"url"`
    GrpcOptions struct {
        SslTarget string `yaml:"ssl-target-name-override"`
    } `yaml:"grpcOptions"`
    TlsCACerts struct {
        Path string `yaml:"path"`
    } `yaml:"tlsCACerts"`
}

type CertificateAuthority struct {
    Url        string `yaml:"url"`
    CAName     string `yaml:"caName"`
    TlsCACerts struct {
        Path string `yaml:"path"`
    } `yaml:"tlsCACerts"`
    HttpOptions struct {
        Verify bool `yaml:'verify'`
    } `yaml:"httpOptions"`
    Registrar struct {
        EnrollId     string `yaml:"enrollId"`
        EnrollSecret string `yaml:"enrollSecret"`
    } `yaml:"registrar"`
}

type Organization struct {
    Name                   string   `yaml:"name"`
    MSPID                  string   `yaml:"mspid"`
    Peers                  []string `yaml:"peers"`
    CertificateAuthorities []string `yaml:"certificateAuthorities"`
    AdminPrivateKey        struct {
        Path string `yaml:"path"`
    } `yaml:"adminPrivateKey"`
    SignedCert struct {
        Path string `yaml:"path"`
    } `yaml:"signedCert"`
}

type Channel struct {
    Orderers   []string `yaml:"orderers"`
    Peers      []string `yaml:"peers"`
    Chaincodes []string `yaml:"chaincodes"`
}

type Client struct {
    Organization string `yaml:"organization"`
    Conenction   struct {
        Timeout struct {
            Peer struct {
                Endorser int `yaml:"endorser"`
                EventHub int `yaml:"eventHub"`
                EventReg int `yaml:"eventReg"`
            } `yaml:"peer"`
            Orderer int `yaml:"orderer"`
        } `yaml:"timeout"`
    } `yaml:"connection"`
}

type ConnectionProfile struct {
    Client        Client                          `yaml:"client"`
    Channels      map[string]Channel              `yaml:"channels"`
    Orderers      map[string]Orderer              `yaml:"orderers"`
    Peers         map[string]Peer                 `yaml:"peers"`
    CA            map[string]CertificateAuthority `yaml:"certificateAuthorities"`
    Organizations map[string]Organization         `yaml:"organizations"`
}