#!/bin/bash -e

# echo $#
if [ $1 == "upgradeDB" ]; then
  if [ $# != 5 ]; then
    echo "Invalid number of arguments. Usage:"
    echo "./upgradeNetwork.sh upgradeDB <msp id> <peer name> <org name> <artifacts location> "
    exit 1
  fi
elif [ $1 == "capabilityUpdate" ]; then
  if [ $# != 10 ]; then
    echo "Invalid number of arguments. Usage:"
    echo "./upgradeNetwork.sh capabilityUpdate <msp id> <peer name> <org name> <artifacts location> <num channels> <capability> <group>"
    exit 1
  fi
fi

MSPID=$2
NAME=$3
ORG_NAME=$4
ARTIFACTS_LOCATION=$5
NUM_CHANNELS=$6
CAPABILITY=$7
GROUP=$8
PEERORG_MSPID=$9
PEERORG_NAME=${10}

modifyConfig(){
  GROUP=$1
  POLICY=$2
  
  if [ $GROUP == "orderer" ]; then
    jq -s '.[0] * {"channel_group":{"groups":{"Orderer": {"values": {"Capabilities": '$POLICY'}}}}}' config.json > modified_config.json
  elif [ $GROUP == "channel" ]; then
    jq -s '.[0] * {"channel_group":{"values": {"Capabilities": '$POLICY'}}}' config.json > modified_config.json
  elif [ $GROUP == "application" ]; then
    jq -s '.[0] * {"channel_group":{"groups":{"Application": {"values": {"Capabilities": '$POLICY'}}}}}' config.json > modified_config.json
  elif [ $GROUP == "consortium" ]; then
    jq -s '.[0] * {"channel_group":{"groups":{"Consortiums":{"groups": {"FabricConsortium": {"groups": '$POLICY'}}}}}}' config.json > modified_config.json
  elif [ $GROUP == "organization" ]; then
    jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": '$POLICY'}}}}' config.json > modified_config.json
  elif [ $GROUP == "apppolicy" ]; then
    jq -s '.[0] * {"channel_group":{"groups":{"Application":{"policies": '$POLICY'}}}}' config.json > modified_config.json
  elif [ $GROUP == "acls" ]; then
    jq -s '.[0] * {"channel_group":{"groups":{"Application":{"values": {"ACLs": {"mod_policy": "Admins", "value": {"acls": '$POLICY'}}}}}}}' config.json > modified_config.json
  fi
}

update(){

  MSPID=$1
  NAME=$2
  ORG_NAME=$3
  ARTIFACTS_LOCATION=$4
  CHANNEL_NAME=$5
  CAPABILITY=$6
  GROUP=$7
  PEERORG_MSPID=$8
  PEERORG_NAME=$9

  export FABRIC_CFG_PATH=$GOPATH/config/
  export CORE_PEER_LOCALMSPID=$MSPID
  export CORE_PEER_ADDRESS=localhost:30000
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_MSPCONFIGPATH="$ARTIFACTS_LOCATION/crypto-config/ordererOrganizations/$ORG_NAME/users/Admin@$ORG_NAME/msp"
  export CORE_PEER_TLS_ROOTCERT_FILE="$ARTIFACTS_LOCATION/crypto-config/ordererOrganizations/$ORG_NAME/orderers/orderer0-$ORG_NAME.$ORG_NAME/tls/ca.crt"

  if [ $GROUP == "orderer" ] || [ $GROUP == "channel" ] || [ $GROUP == "application" ]; then
    POLICY=('{"mod_policy":"Admins","value":{"capabilities":{"'$CAPABILITY'":{}}},"version":"0"}')
  elif [ $GROUP == "consortium" ] || [ $GROUP == "organization" ]; then
    POLICY=('{"'$PEERORG_NAME'":{"policies":{"Endorsement":{"mod_policy":"Admins","policy":{"type":1,"value":{"identities":[{"principal":{"msp_identifier":"'$PEERORG_MSPID'","role":"MEMBER"},"principal_classification":"ROLE"}],"rule":{"n_out_of":{"n":1,"rules":[{"signed_by":0}]}},"version":0}},"version":"0"}}}}')
  elif [ $GROUP == "apppolicy" ]; then
    POLICY=('{"Endorsement":{"mod_policy":"Admins","policy":{"type":3,"value":{"rule":"ANY","sub_policy":"Endorsement"}},"version":"0"},"LifecycleEndorsement":{"mod_policy":"Admins","policy":{"type":3,"value":{"rule":"ANY","sub_policy":"Endorsement"}},"version":"0"}}')
  elif [ $GROUP == "acls" ]; then
    POLICY=('{"_lifecycle/CommitChaincodeDefinition":{"policy_ref":"/Channel/Application/Writers"},"_lifecycle/QueryChaincodeDefinition":{"policy_ref":"/Channel/Application/Readers"},"_lifecycle/QueryNamespaceDefinitions":{"policy_ref":"/Channel/Application/Readers"}}')
  fi

  rm -rf config
  mkdir config
  cd config/

  peer channel fetch config config_block.pb -o $CORE_PEER_ADDRESS -c $CHANNEL_NAME --tls --cafile $CORE_PEER_TLS_ROOTCERT_FILE --ordererTLSHostnameOverride $NAME
  configtxlator proto_decode --input config_block.pb --type common.Block --output /tmp/data.json
  cat /tmp/data.json | jq .data.data[0].payload.data.config > config.json
  
  echo $POLICY
  modifyConfig $GROUP $POLICY

  configtxlator proto_encode --input config.json --type common.Config --output config.pb
  configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
  configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output modified_update.pb
  configtxlator proto_decode --input modified_update.pb --type common.ConfigUpdate --output /tmp/data.json 
  cat /tmp/data.json | jq . > modified_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat modified_update.json)'}}}' | jq . > modified_update_in_envelope.json
  configtxlator proto_encode --input modified_update_in_envelope.json --type common.Envelope --output modified_update_in_envelope.pb
  if [ $GROUP == "application" ] || [ $GROUP == "organization" ] || [ $GROUP == "apppolicy" ] || [ $GROUP == "acls" ] || [ $GROUP == "consortium" ]; then
    export CORE_PEER_LOCALMSPID=$PEERORG_MSPID
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_MSPCONFIGPATH="$ARTIFACTS_LOCATION/crypto-config/peerOrganizations/$PEERORG_NAME/users/Admin@$PEERORG_NAME/msp"
    peer channel signconfigtx -f modified_update_in_envelope.pb
  fi
  export CORE_PEER_LOCALMSPID=$MSPID
  export CORE_PEER_ADDRESS=localhost:30000
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_MSPCONFIGPATH="$ARTIFACTS_LOCATION/crypto-config/ordererOrganizations/$ORG_NAME/users/Admin@$ORG_NAME/msp"
  export CORE_PEER_TLS_ROOTCERT_FILE="$ARTIFACTS_LOCATION/crypto-config/ordererOrganizations/$ORG_NAME/orderers/orderer0-$ORG_NAME.$ORG_NAME/tls/ca.crt"
  peer channel update -f modified_update_in_envelope.pb -c $CHANNEL_NAME -o $CORE_PEER_ADDRESS --tls --cafile $CORE_PEER_TLS_ROOTCERT_FILE --ordererTLSHostnameOverride $NAME
  rm *.json *.pb
}

upgradeDB(){
  MSPID=$1
  NAME=$2
  ORG_NAME=$3
  ARTIFACTS_LOCATION=$4

  export FABRIC_CFG_PATH=$GOPATH/config/
  export CORE_PEER_LOCALMSPID=$MSPID
  export CORE_PEER_MSPCONFIGPATH="$ARTIFACTS_LOCATION/crypto-config/peerOrganizations/$ORG_NAME/users/Admin@$ORG_NAME/msp"
  export CORE_PEER_TLS_ROOTCERT_FILE="$ARTIFACTS_LOCATION/crypto-config/peerOrganizations/$ORG_NAME/peers/$NAME.$ORG_NAME/tls/ca.crt"

  cd configFiles/backup/$NAME
  export CORE_PEER_FILESYSTEMPATH=$PWD
  peer node upgrade-dbs
  cd -
}

capabilityUpdate(){
  sleep 15
  if [ $7 == "orderer" ] || [ $7 == "channel" ] || [ $7 == "consortium" ]; then
    CHANNELS=("orderersystemchannel")
  elif [ $7 == "application" ] || [ $7 == "organization" ] || [ $7 == "apppolicy" ] || [ $7 == "acls" ]; then
    CHANNELS=()
  fi

  for (( i=0; i < $5; ++i ))
  do
    CHANNELS+=("defaultchannel$i")
  done

  for i in ${CHANNELS[*]}
  do
    echo "Config update to change "$7" capability for channel $i "
    update $1 $2 $3 $4 $i $6 $7 $8 $9
  done
}

echo "$1 $MSPID $NAME $ORG_NAME $ARTIFACTS_LOCATION $NUM_CHANNELS $CAPABILITY $GROUP $PEERORG_MSPID $PEERORG_NAME"
$1 $MSPID $NAME $ORG_NAME $ARTIFACTS_LOCATION $NUM_CHANNELS $CAPABILITY $GROUP $PEERORG_MSPID $PEERORG_NAME