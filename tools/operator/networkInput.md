# Network Input File
- Network input file consists of information needed in generating configuration
files of fabric network and launching it. Here is a sample network input file:

```yaml
fabric_version: 1.4.2
db_type: couchdb
peer_fabric_logging_spec: error
orderer_fabric_logging_spec: error
tls: true
metrics: false

artifacts_location: /home/ibmadmin/go/src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen/

orderer:
  orderertype: kafka
  batchsize:
    maxmessagecount: 500
    absolutemaxbytes: 10 MB
    preferredmaxbytes: 2 MB
  batchtimeout: 2s

  etcdraft_options:
    TickInterval: 500ms
    ElectionTick: 10
    HeartbeatTick: 1
    MaxInflightBlocks: 5
    SnapshotIntervalSize: 100 MB

kafka:
  num_kafka: 5
  num_kafka_replications: 3
  num_zookeepers: 3

orderer_organizations:
- name: ordererorg1
  msp_id: OrdererOrgExampleCom
  num_orderers: 1
  num_ca: 1

peer_organizations:
- name: org1
  msp_id: Org1ExampleCom
  num_peers: 2
  num_ca: 1
- name: org2
  msp_id: Org2ExampleCom
  num_peers: 2
  num_ca: 1


orderer_capabilities:
  V1_4_2: true

channel_capabilities:
  V1_4_2: true

application_capabilities:
  V1_4_2: true

num_channels: 10

k8s:
  service_type: NodePort
  data_persistence: true
  storage_class: default
  storage_capacity: 20Gi
```

## Options in Network Input
### fabric_version
   - Description: Fabric version to be used in launching fabric network.
   If `fabric_version` is given without stable in it, for example: `1.4.2` or
   `latest`, it will use images from `hyperledger/` docker hub.
   If fabric_version is given with stable in the value, it will pull images
   from `nexus.hyperledger.org`. 
   - Supported Values: 1.4.2 or later
   - Example: `fabric_version: 1.4.2`
   `fabric_version: 1.4.2-stable`

### db_type
   - Description: Peer state ledger type to be used while launching peers
   - Supported Values: couchdb, goleveldb
   - Example: `db_type: couchdb`

### peer_fabric_logging_spec
   - Description: Desired fabric logging spec to be used for all peers.
   - Supported Values: Refer <https://hyperledger-fabric.readthedocs.io/en/latest/logging-control.html>
   to set peer fabric logging spec value
   - Example: `peer_fabric_logging_spec: error`
   `peer_fabric_logging_spec: info:lockbasedtxmgr,couchdb,statecouchdb,gossip.privdata=debug`

### orderer_fabric_logging_spec
   - Description: Desired fabric logging spec to be used for all orderers
   - Supported Values: Refer <https://hyperledger-fabric.readthedocs.io/en/latest/logging-control.html>
   to set orderer fabric logging spec value
   - Example: `orderer_fabric_logging_spec: info`
   `orderer_fabric_logging_spec: info:policies=debug`

### tls
   - Description: `tls` is used to use server authentication between fabric nodes when `tls` is set
   to `true`, use server-client authentication between fabric nodes when `tls` is set to `mutual`,
   use no tls communication when `tls` is set to `false`
   - Supported Values: true, false, mutual
   - Example: `tls: true`

### metrics
   - Description: `metrics` is used to enable fabric metrics scraping to prometheus in kubernetes cluster.
   To scrape fabric metrics, prometheus has to be launched prior to fabric network. If `metrics` is set
   to `true`, it will enable scraping of fabric metrics. If `metrics` is set to `false`, it will not
   enable scraping of fabric metrics
   - Supported Values: true, false
   - Example: `metrics: true`

### artifacts_location
   - Description: `artifacts_location` is used to specify location in local file system to which
   crypto-config, channel-artifacts and connection profiles will be saved
   - Supported Values: absolute path to location in your local
   - Example: `artifacts_location: /home/ibmadmin/go/src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen/`

### orderer
   - Description: `orderer` section is used to define configuration settings for orderer system channel

   #### orderertype
      - Description: `orderertype` is used to define consensus type to be used in fabric network
      - Supported Values: solo, kafka, etcdraft
      - Example: `orderertype: kafka`
      `orderertype: etcdraft`

   #### batchsize
      - Description: `batchsize` section is used to define block settings in fabric network

      ##### maxmessagecount
          - Description: `maxmessagecount` is used to set maximum messages per block in fabric network
          - Supported Values: Integer to set maximum messages allowed in a batch
          - Example: `maxmessagecount: 10`

      ##### absolutemaxbytes
           - Description: `absolutemaxbytes` is used to set absolute maximum number of bytes
           allowed for the serialized messages in a batch
           - Supported Values: Refer <https://github.com/hyperledger/fabric/blob/master/sampleconfig/configtx.yaml>
           to set value for `absolutemaxbytes`
           - Example: `absolutemaxbytes: 10 MB`

      ##### preferredmaxbytes
           - Description: `preferredmaxbytes` is used to set preferred maximum number of bytes
           allowed for the serialized messages in a batch
           - Supported Values: Refer <https://github.com/hyperledger/fabric/blob/master/sampleconfig/configtx.yaml>
           to set value for `preferredmaxbytes`
           - Example: `preferredmaxbytes: 2 MB`

   #### batchtimeout
       - Description: `batchtimeout` is used to wait before creating a batch in fabric network
       - Supported Values: Value in seconds to wait before creating a batch
       - Example: `batchtimeout: 2s`

   #### etcdraft_options
       - Description: `etcdraft_options` section is referred and used only when `orderertype` is set
       as `etcdraft`. The following are `etcdfraft` configurations:

       ##### TickInterval
           - Description: `TickInterval` is the time interval between two Node.Tick invocations
           - Supported Values: Refer <https://github.com/hyperledger/fabric/blob/master/sampleconfig/configtx.yaml>
           to set tick interval between raft nodes
           - Example: `TickInterval: 500ms`

       ##### ElectionTick
           - Description: `ElectionTick` is the number of Node.Tick invocations that must pass
           between elections
           - Supported Values: Refer <https://github.com/hyperledger/fabric/blob/master/sampleconfig/configtx.yaml>
           to set election tick between raft nodes
           - Example: `ElectionTick: 10`

       ##### HeartbeatTick
           - Description: `HeartbeatTick` is the number of Node.Tick invocations that must
           pass between heartbeats
           - Supported Values: Refer <https://github.com/hyperledger/fabric/blob/master/sampleconfig/configtx.yaml>
           to set heartbeat tick between raft nodes
           - Example: `HeartbeatTick: 1`

      ##### MaxInflightBlocks
           - Description: `MaxInflightBlocks` limits the max number of in-flight append messages
           during optimistic replication phase
           - Supported Values: Refer <https://github.com/hyperledger/fabric/blob/master/sampleconfig/configtx.yaml>
           to set maximum inflight blocks between raft nodes
           - Example: `MaxInflightBlocks: 5`

      ##### SnapshotIntervalSize
          - Description: `SnapshotIntervalSize` defines number of bytes per which a snapshot is taken
          - Supported Values: Refer <https://github.com/hyperledger/fabric/blob/master/sampleconfig/configtx.yaml>
           to set snapshot interval size in raft
          - Example: `SnapshotIntervalSize: 100 MB`

### kafka
   - Description: `kafka` section is used when `orderertype` as `kafka` and to define number of
   kafka's, number of zookeeper's to be launched and number of kafka replications to have in
   kafka cluster

   #### num_kafka
      - Description: `num_kafka` is used to set number of kafka to be launched in fabric network
      - Supported Values: Value to launch number of kafka in fabric network. Preferred value
      is 3 or higher
      - Example: `num_kafka: 5`

   #### num_kafka_replications
      - Description: `num_kafka_replications` is used to set `KAFKA_DEFAULT_REPLICATION_FACTOR`
      while launching fabric network
      - Supported Values: Value to set number of kafka replications. Value should be less than or
      equal to `num_kafka`
      - Example: `num_kafka_replications: 3`

   #### num_zookeepers
      - Description: `num_zookeepers` is used to set number of zookeepers to be launched
      in fabric network
      - Supported Values: Value to launch number of zookeepers in fabric network
      - Example: `num_zookeepers: 3`

### orderer_organizations
   - Description: `orderer_organizations` section is used to list all orderer organizations in
   fabric network. For example:

```yaml
orderer_organizations:
   - name: ordererorg1
      msp_id: OrdererOrg1ExampleCom
      num_orderers: 3
      num_ca: 0
   - name: ordererorg2
      msp_id: OrdererOrg2ExampleCom
      num_orderers: 2
      num_ca: 0
```

   #### name
       - Description: `name` is used to set orderer organization name
       - Supported Values: Any unique string which should start with smaller case letter,
       can contain smaller case letters, capital letters, numbers and `-` special character
       only in string
       - Example: `- name: ordererorg1`

   #### msp_id
       - Description: `msp_id` is used to set mspID for listed orderer organization 
       - Supported Values: Any unique string which can contain smaller case letters,
       capital letters, numbers
       - Example: `msp_id: OrdererOrgExampleCom`

   #### num_orderers
       - Description: `num_orderers` is used to set number of orderers in listed orderer
       organization
       - Supported Values: Value to launch number of orderers in listed orderer organization
       in fabric network
       - Example: `num_orderers: 1`

   #### num_ca:
       - Description: `num_ca` is used to set number of ca in listed orderer organization
       - Supported Values: Value to launch number of ca in listed orderer organization
       in fabric network
       - Example: `num_ca: 1`

### peer_organizations:
   - Description: `peer_organizations` section is used to list all peer organizations in
   fabric network. For example:

```yaml
peer_organizations:
- name: org1
   msp_id: Org1ExampleCom
   num_peers: 2
   num_ca: 1
- name: org2
   msp_id: Org2ExampleCom
   num_peers: 2
   num_ca: 1
```

   #### name:
       - Description: `name` is used to set peer organization name
       - Supported Values: Any unique string which should start with smaller case letter,
       can contain smaller case letters, capital letters, numbers and `-` special character
       only in string
       - Example: `- name: org1`

   #### msp_id:
       - Description: `msp_id` is used to set mspID for listed peer organization
       - Supported Values: Any unique string which can contain smaller case letters,
       capital letters, numbers
       - Example: `msp_id: Org1ExampleCom`

   #### num_peers:
       - Description: `num_peers` is used to set number of peers in listed peer organization
       - Supported Values: Value to launch number of peers in listed peer organization
       in fabric network
       - Example: `num_peers: 1`

   #### num_ca
       - Description: `num_ca` is used to set number of ca in listed peer organization
       - Supported Values: Value to launch number of ca in listed peer organization
       in fabric network
       - Example: `num_ca: 1`

### orderer_capabilities:
   - Description: `orderer_capabilities` is used to set orderer group capabilities in
   orderer system channel and application channels
   - Supported Values: Refer <https://github.com/hyperledger/fabric/blob/master/sampleconfig/configtx.yaml>
   to set orderer group capabilities
   - Example:
		```
		orderer_capabilities:
		  V1_4_2: true```

### channel_capabilities:
   - Description: `channel_capabilities` is used to set channel group capabilities in
   fabric network
   - Supported Values: Refer <https://github.com/hyperledger/fabric/blob/master/sampleconfig/configtx.yaml>
   to set channel group capabilities
   - Example:
		```
		channel_capabilities:
		  V1_4_2: true```

### application_capabilities:
   - Description: `application_capabilities` is used to set application group capabilities in
   fabric network
   - Supported Values: Refer <https://github.com/hyperledger/fabric/blob/master/sampleconfig/configtx.yaml>
   to set application group capabilities
   - Example:
		```
		application_capabilities:
		  V1_4_2: true```

### num_channels:
   - Description: `num_channels` is used to set number of channel configuration transactions to be created
   using `testorgschannel` as base name
   - Supported Values: Number of channels needed in fabric network
   - Example: `num_channels: 10`

### k8s:
   - Description: `k8s` section is used while launching fabric network in kubernetes cluster. This section
   will be ignored while launching fabric network locally

   #### service_type:
       - Description: `service_type` is used to set type of service to be used for pods in kubernetes. Refer
       <https://kubernetes.io/docs/concepts/services-networking/service/> for types of services
       - Supported Values: ClusterIP, NodePort, LoadBalancer
       - Example: `service_type: NodePort`

   #### data_persistence:
       - Description: `data_persistence` is used to enable data persistence for fabric network. If it is set
       to `true`, it uses persistent volume claims using `storage_class` and `storage_capacity`. If it is set
       to `local`, it uses local storage on the worker nodes in kubernetes cluster. If it is set to `false`. it
       will not enable data persistence in fabric network
       - Supported Values: true, false, local
       - Example: `data_persistence: true`

   #### storage_class:
       - Description: `storage_class` is used to determine which storage class to be used for creating persistent
       volume claims when `data_persistence` is set to `true`
       - Supported Values: Name of storage class available in kubernetes cluster 
       - Example: `storage_class: default`

   #### storage_capacity:
       - Description: `storage_capacity` is used to determine how much capacity in GB to be allocated for each
       persistent volume claim when `data_persistence` is set to `true`
       - Supported Values: Any number in Gi
       - Example: `storage_capacity: 20Gi`