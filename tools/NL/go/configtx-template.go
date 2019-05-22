package main

func DefaultConfigTxTemplate() string {
	const template = `---{{$msp := .ArtifactsLocation}}	
  Organizations:{{ range .OrdererOrganizations }}
    - &{{ .Name }}
      Name: {{ .Name }}
      ID: {{ .Name }}
      MSPDir: {{ $msp }}crypto-config/ordererOrganizations/{{ .Name }}/msp
      Policies:
        Readers:
          Type: Signature
          Rule: OR('{{.Name}}.member')
        Writers:
          Type: Signature
          Rule: OR('{{.Name}}.member')
        Admins:
          Type: Signature
          Rule: OR('{{.Name}}.admin')
    {{- end }}
    {{- range .PeerOrganizations }}
    - &{{ .Name }}
      Name: {{ .Name }}
      ID: {{ .Name }}
      MSPDir: {{ $msp }}crypto-config/peerOrganizations/{{ .Name }}/msp
      Policies:
        Readers:
          Type: Signature
          Rule: OR('{{.Name}}.admin', '{{.Name}}.peer' )
        Writers:
          Type: Signature
          Rule: OR('{{.Name}}.admin', '{{.Name}}.client')
        Admins:
          Type: Signature
          Rule: OR('{{.Name}}.admin')
    {{ end }}
  Capabilities:
    Global: &ChannelCapabilities
      V1_3: true
  
    Orderer: &OrdererCapabilities
      V1_1: true
  
    Application: &ApplicationCapabilities
      V1_3: true
  
  Orderer: &OrdererDefaults
    OrdererType: {{ .OrdererConfig.OrdererType }}
    Addresses:{{ range .OrdererAddresses }}
      - {{ . }}
    {{- end }}
    BatchTimeout: {{ .OrdererConfig.Batchtimeout }}
    BatchSize:
      MaxMessageCount: {{ .OrdererConfig.Batchsize.Maxmessagecount }}
      AbsoluteMaxBytes: {{ .OrdererConfig.Batchsize.Absolutemaxbytes }}
      PreferredMaxBytes: {{ .OrdererConfig.Batchsize.Preferredmaxbytes }}
  
    {{- if eq .OrdererConfig.OrdererType "etcdraft" }}
    EtcdRaft:
      Consenters:{{ range .OrdererCerts }}
        - Host: {{ .Host }}
          Port: 7050
          ClientTLSCert: {{ .TlsCertLocation }}
          ServerTLSCert: {{ .TlsCertLocation }}
      {{- end }}
      Options:
        TickInterval: {{ .OrdererConfig.Etcdraftoptions.TickInterval }}
        ElectionTick: {{ .OrdererConfig.Etcdraftoptions.ElectionTick }}
        HeartbeatTick: {{ .OrdererConfig.Etcdraftoptions.HeartbeatTick }}
        MaxInflightBlocks: {{ .OrdererConfig.Etcdraftoptions.MaxInflightBlocks }}
        SnapshotIntervalSize: {{ .OrdererConfig.Etcdraftoptions.SnapshotIntervalSize }}
    {{- end }}
    Organizations: {{ range .OrdererOrganizations }}
      - *{{ .Name }}
      {{- end }}
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
        BlockValidation:
            Type: ImplicitMeta
            Rule: "ANY Writers"
    Capabilities:
      <<: *OrdererCapabilities
  Application: &ApplicationDefaults
    Organizations:{{ range .PeerOrganizations }}
      - *{{ .Name }}
    {{- end}}
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
    Capabilities:
      <<: *ApplicationCapabilities
  
  Channel: &ChannelDefaults
      Policies:
          Readers:
              Type: ImplicitMeta
              Rule: "ANY Readers"
          Writers:
              Type: ImplicitMeta
              Rule: "ANY Writers"
          Admins:
              Type: ImplicitMeta
              Rule: "MAJORITY Admins"
      Capabilities:
        <<: *ChannelCapabilities
  Profiles:
    testorgschannel:
      <<: *ChannelDefaults
      Consortium: FabricConsortium
      Application:
        <<: *ApplicationDefaults
      Orderer:
        <<: *OrdererDefaults
        {{- if eq .OrdererConfig.OrdererType "etcdraft" }}
        EtcdRaft:
          Consenters:{{ range .OrdererCerts }}
            - Host: {{ .Host }}
              Port: 7050
              ClientTLSCert: {{ .TlsCertLocation }}
              ServerTLSCert: {{ .TlsCertLocation }}
          {{- end }}{{- end }}
    testOrgsOrdererGenesis:
      <<: *ChannelDefaults
      Capabilities:
        <<: *ChannelCapabilities
      Orderer:
        <<: *OrdererDefaults
      Consortiums:
        FabricConsortium:
          Organizations:{{ range .PeerOrganizations }}
            - *{{ .Name }}
          {{- end}}
  `
	return template
}
