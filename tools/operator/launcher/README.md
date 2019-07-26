# Fabric Network Launcher
- A tool to launch fabric network on kubernetes cluster or local machine with a docker-compose file using a network input file and gives back connection profiles for each peer organization to use with any client. This uses ytt to generate all necessary configuration files and a go program to launch fabric network

## Prerequisites:
- Go 1.11.0 or above
- yaml.v2 go package (go get gopkg.in/yaml.v2)
- Fabric binaries in $PATH
- Kubernetes cluster if launching fabric network on kubernetes cluster
- Docker and Docker-compose if launching fabric network locally

## Network Input File:
- Network input file consists of information needed in generating configuration files of fabric network and launching it. Here is a sample network input file:

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
- Fields:
    - fabric_version:
        Description: 
        Supported Values: 1.4.2 or later
        Example: `fabric_version: 1.4.2`

    - db_type:
        Description: 
        Supported Values: couchdb, goleveldb
        Example: `db_type: couchdb`

    - peer_fabric_logging_spec:
        Description:
        Supported Values: string to set log levels for peers
        Example: `peer_fabric_logging_spec: info:lockbasedtxmgr,couchdb,statecouchdb,gossip.privdata=debug`

    - orderer_fabric_logging_spec:
        Description:
        Supported Values: string to set log levels for orderers
        Example: `orderer_fabric_logging_spec: info:policies=debug`

    - tls:
        Description:
        Supported Values: true, false, mutual
        Example: `tls: true`

    - metrics:
        Description:
        Supported Values: true, false
        Example: `metrics: true`

    - artifacts_location:
        Description:
        Supported Values: absolute path to location in your local where to save certificates, channel configuration transactions and connection profiles
        Example: `artifacts_location: /home/ibmadmin/go/src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen/`

    - orderer:
        Description: 
        - orderertype:
            Description:
            Supported Values: solo, kafka, etcdraft
            Example: `orderertype: kafka`
        - batchsize:
            Description:
            - maxmessagecount:
                Description:
                Supported Values: Integer to set maximum messages per block
                Example: `maxmessagecount: 10`
            - absolutemaxbytes:
                Description:
                Supported Values: Value to set absolute maximum bytes per block
                Example: `absolutemaxbytes: 10 MB`
            - preferredmaxbytes:
                Description:
                Supported Values: Value to set preferred maximum bytes per block
                Example: `preferredmaxbytes: 2 MB`
        - batchtimeout:
            Description:
            Supported Values: Value in seconds to set block batch timeout
            Example: `batchtimeout: 2s`

        - etcdraft_options:
            Description:
            - TickInterval:
                Description:
                Supported Values: Value to set tick interval between raft nodes
                Example: `TickInterval: 500ms`
            - ElectionTick:
                Description:
                Supported Values: Value to set election tick between raft nodes
                Example: `ElectionTick: 10`
            - HeartbeatTick:
                Description:
                Supported Values: Value to set heartbeat tick between raft nodes
                Example: `HeartbeatTick: 1`
            - MaxInflightBlocks:
                Description:
                Supported Values: Value to set maximum inflight blocks between raft nodes
                Example: `MaxInflightBlocks: 5`
            - SnapshotIntervalSize
                Description:
                Supported Values: Value to set snapshot interval size in raft
                Example: `SnapshotIntervalSize: 100 MB`

    - kafka:
        Description:
        - num_kafka:
            Description:
            Supported Values:
            Example: `num_kafka: 5`
        - num_kafka_replications:
            Description:
            Supported Values:
            Example: `num_kafka_replications: 3`
        - num_zookeepers:
            Description:
            Supported Values:
            Example: `num_zookeepers: 3`

    - orderer_organizations:
        - name:
            Description:
            Supported Values:
            Example: `- name: ordererorg1`
        - msp_id:
            Description:
            Supported Values:
            Example: `msp_id: OrdererOrgExampleCom`
        - num_orderers:
            Description:
            Supported Values:
            Example: `num_orderers: 1`
        - num_ca:
            Description:
            Supported Values:
            Example: `num_ca: 1`

    - peer_organizations:
        - name:
            Description:
            Supported Values:
            Example: `- name: org1`
        - msp_id:
            Description:
            Supported Values:
            Example: `msp_id: Org1ExampleCom`
        - num_peers:
            Description:
            Supported Values:
            Example: `num_peers: 1`
        - num_ca:
            Description:
            Supported Values:
            Example: `num_ca: 1`
    
    - orderer_capabilities:
        Description:
        Supported Values:
        Example: 
		```
		orderer_capabilities:
		  V1_4_2: true```

    - channel_capabilities:
        Description:
        Supported Values:
        Example: 
		```
		channel_capabilities:
		  V1_4_2: true```

    - application_capabilities:
        Description:
        Supported Values:
        Example: 
		```
		application_capabilities:
		  V1_4_2: true```

    - num_channels:
        Description:
        Supported Values:
        Example: `num_channels: 10`

    - k8s:
        Description:
        - service_type:
            Description:
            Supported Values:
            Example: `service_type: NodePort`
        - data_persistence:
            Description:
            Supported Values:
            Example: `data_persistence: true`
        - storage_class:
            Description:
            Supported Values:
            Example: `storage_class: default`
        - storage_capacity:
            Description:
            Supported Values:
            Example: `storage_capacity: 20Gi`

## Execution:
### On Kubernetes Cluster:
To launch fabric network in kubernetes cluster, need kube config file for cluster and network input file
```go run launcher.go -i <path/to/network input file> -k <path/to/kube config file> -m up``` or 
```go run launcher.go -i <path/to/network input file> -k <path/to/kube config file>```
To take down the launched fabric network from the above
```go run launcher.go -i <path/to/network input file> -k <path/to/kube config file> -m down```
### Local:
To launch fabric network locally using network input file
```go run launcher.go -i <path/to/network input file> -m up``` or
```go run launcher.go -i <path/to/network input file>```

To take down launched fabric network locally
```go run launcher.go -i <path/to/network input file> -m down```

## Verification:
### On Kubernetes Cluster:
To verify if fabric network is launched successfully or not in kubernetes cluster:
```export KUBECONFIG=<path/to/kube config file>```
```kubectl get pods```
```kubectl get services```
### Local:
To verify if fabric network is launched successfully or not locally:
``` docker ps -a```