#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# default directories
FabricDir="$GOPATH/src/github.com/hyperledger/fabric-test/fabric"
MSPDir="$GOPATH/src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen"
SRCMSPDir="/opt/hyperledger/fabric/msp/crypto-config"

function printHelp {

   echo "Usage: "
   echo " ./networkLauncher.sh [opt] [value] "
   echo "    -a: network action [up|down], default=up"
   echo "    -x: number of ca, default=0"
   echo "    -d: ledger database type, default=goleveldb"
   echo "    -f: profile string, default=test"
   echo "    -h: hash type, default=SHA2"
   echo "    -k: number of kafka, default=0"
   echo "    -e: number of kafka replications, default=0"
   echo "    -z: number of zookeepers, default=0"
   echo "    -n: number of channels, default=1"
   echo "    -o: number of orderers, default=1"
   echo "    -p: number of peers per organization, default=1"
   echo "    -r: number of organizations, default=1"
   echo "    -s: security type, default=256"
   echo "    -t: ledger orderer service type [solo|kafka|etcdraft], default=solo"
   echo "    -w: host ip, default=0.0.0.0"
   echo "    -l: peer logging level [CRITICAL|ERROR|WARNING|NOTICE|INFO|DEBUG], default=ERROR"
   echo "    -q: orderer logging level [CRITICAL|ERROR|WARNING|NOTICE|INFO|DEBUG], default=ERROR"
   echo "    -c: batch timeout, default=2s"
   echo "    -B: batch size, default=10"
   echo "    -F: local MSP base directory, default=$GOPATH/src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen/"
   echo "    -G: src MSP base directory, default=/opt/hyperledger/fabric/msp/crypto-config"
   echo "    -S: TLS enablement [disabled|serverauth|clientauth], default=disabled"
   echo "    -C: company name, default=example.com "
   echo "    -M: JSON file containing organization and MSP name mappings (optional) "
   echo "    -y: yaml file contains network specification, other options are ignored"
   echo " "
   echo " example: "
   echo " ./networkLauncher.sh -o 1 -x 2 -r 2 -p 2 -k 1 -z 1 -n 2 -t kafka -f test -w 10.120.223.35 "
   echo " ./networkLauncher.sh -o 1 -x 2 -r 2 -p 2 -n 1 -f test -w 10.120.223.35 "
   echo " ./networkLauncher.sh -o 1 -x 2 -r 2 -p 2 -k 1 -z 1 -n 2 -t kafka -f test -w 10.120.223.35 -S serverauth "
   echo " ./networkLauncher.sh -o 4 -x 2 -r 2 -p 2 -k 4 -z 4 -n 2 -t kafka -f test -w localhost -S serverauth "
   echo " ./networkLauncher.sh -o 3 -x 6 -r 6 -p 2 -k 3 -z 3 -n 3 -t kafka -f test -w localhost -S serverauth "
   echo " ./networkLauncher.sh -o 3 -x 6 -r 6 -p 2 -k 3 -z 3 -n 3 -t kafka -f test -w localhost -S clientauth -l INFO -q DEBUG"
   echo " ./networkLauncher.sh -o 1 -x 5 -r 5 -p 1 -k 1 -z 1 -n 1 -C trade.com -M sampleOrgMap.json -t kafka -f test -w localhost -S enabled"
   echo " ./networkLauncher.sh -o 3 -x 6 -r 6 -p 2 -n 3 -t etcdraft -f test -w localhost -S serverauth "
   exit
}

#defaults
PROFILE_STRING="test"
nCA=0
nOrderer=1
nOrg=1
nPeersPerOrg=1
ledgerDB="goleveldb"
hashType="SHA2"
secType="256"
TLSEnabled="disabled"
MutualTLSEnabled="disabled"
nChannel=1
HostIP1="0.0.0.0"
comName="example.com"
networkAction="up"
BuildDir=$GOPATH/src/github.com/hyperledger/fabric-test/fabric/.build/bin

# logging spec
peerLogSpec="ERROR"
ordererLogSpec="ERROR"

## orderer
ordererType="solo"
batchTimeOut="2s"
batchsizeMaxmessagecount=500
batchsizeAbsolutemaxbytes="10 MB"
batchsizePreferredmaxbytes="2 MB"

## orderer: kafka
nKafka=0
nReplica=0
nZoo=0

## orderer: ETCDRAFT
raftTickInterval="500ms"
raftElectionTick=10
raftHeartbeatTick=1
raftMaxInflightBlocks=5
raftSnapshotIntervalSize="100 MB"

orgMap=
orgMapParam=


# yaml parser
function yamlParser {
    TLSEnabled=`yq r $yamlF tls`
    ledgerDB=`yq r $yamlF db_type`
    echo "[yamlParser] TLSEnabled=$TLSEnabled ledgerDB=$ledgerDB"

    peerLogSpec=`yq r $yamlF peer_fabric_logging_spec`
    ordererLogSpec=`yq r $yamlF orderer_fabric_logging_spec`
    metrics=`yq r $yamlF metrics`
    echo "[yamlParser] peerLogSpec=$peerLogSpec ordererLogSpec=$ordererLogSpec metrics=$metrics"
    certs_location=`yq r $yamlF certs_location`
    echo "[yamlParser] certs_location=$certs_location"

    nChannels=`yq r $yamlF num_of_channels`

    #organisations
    tmp=`yq r in.yaml organizations[*].name`
    echo "org length: ${#tmp[@]}"
    for (( i=0; i<=${#tmp[@]}; i++ ))
    do
        t1=`yq r in.yaml organizations[$i].name`
        echo "i=$i, t1: $t1"
        if [ "$t1" != "ordererorg" ]; then
            nCA=`yq r $yamlF organizations[$i].num_of_ca`
            nOrg=`yq r $yamlF organizations[$i].num_of_orgs`
            nPeersPerOrg=`yq r $yamlF organizations[$i].num_of_peer_orgs`
            nOrderer=`yq r $yamlF organizations[$i].num_of_orderers`
            echo "[yamlParser] nChannels=$nChannels, nCA=$nCA, nOrg=$nOrg, nPeersPerOrg=$nPeersPerOrg, nOrderer=$nOrderer"
        fi
    done

    #for ( i=0; i<${#Chaincode[@]}; i++ )
    nCA=`yq r $yamlF organizations.num_of_ca`
    nOrg=`yq r $yamlF organizations.num_of_orgs`
    nPeersPerOrg=`yq r $yamlF organizations.num_of_peer_orgs`
    nOrderer=`yq r $yamlF organizations.num_of_orderers`
    echo "[yamlParser] nChannels=$nChannels, nCA=$nCA, nOrg=$nOrg, nPeersPerOrg=$nPeersPerOrg, nOrderer=$nOrderer"

    ordererType=`yq r $yamlF orderer.orderertype`
    echo "[yamlParser] ordererType=$ordererType"
    if [ "$ordererType" == "kafka" ]; then
        nKafka=`yq r $yamlF kafka.num_of_kafka`
        nReplica=`yq r $yamlF kafka.num_of_kafka_replications`
        nZoo=`yq r $yamlF kafka.num_of_zookeepers`
        echo "[yamlParser] kafka: nKafka=$nKafka, nReplica=$nReplica, nZoo=$nZoo"
    elif [ "$ordererType" == "etcdraft" ]; then
        raftTickInterval=`yq r $yamlF orderer.etcdraft_options.TickInterval`
        raftElectionTick=`yq r $yamlF orderer.etcdraft_options.ElectionTick`
        raftHeartbeatTick=`yq r $yamlF orderer.etcdraft_options.HeartbeatTick`
        raftMaxInflightBlocks=`yq r $yamlF orderer.etcdraft_options.MaxInflightBlocks`
        raftSnapshotIntervalSize=`yq r $yamlF orderer.etcdraft_options.SnapshotIntervalSize`
        echo "[yamlParser] raft: TickInterval=$raftTickInterval, ElectionTick=$raftElectionTick, HeartbeatTick=$raftHeartbeatTick, MaxInflightBlocks=$raftMaxInflightBlocks, SnapshotIntervalSize=$raftSnapshotIntervalSize"
    fi
    batchTimeOut=`yq r $yamlF orderer.batchtimeout`
    echo "[yamlParser] batchTimeOut=$batchTimeOut"
    batchsizeMaxmessagecount=`yq r $yamlF orderer.batchsize.maxmessagecount`
    batchsizeAbsolutemaxbytes=`yq r $yamlF orderer.batchsize.absolutemaxbytes`
    batchsizePreferredmaxbytes=`yq r $yamlF orderer.batchsize.preferredmaxbytes`
    echo "[yamlParser] batchsizeMaxmessagecount=$batchsizeMaxmessagecount, batchsizeAbsolutemaxbytes=$batchsizeAbsolutemaxbytes batchsizePreferredmaxbytes=$batchsizePreferredmaxbytes"
}

while getopts ":a:z:x:d:f:h:k:e:n:o:p:r:t:s:w:l:q:c:B:F:G:S:C:M:y:" opt; do
  case $opt in
    # peer environment options
    a)
      networkAction="$OPTARG"
      echo "network action: $networkAction"
      ;;
    x)
      nCA=$OPTARG
      echo "number of CA: $nCA"
      ;;
    d)
      ledgerDB=$OPTARG
      echo "ledger state database type: $ledgerDB"
      ;;

    f)
      PROFILE_STRING=$OPTARG
      echo "PROFILE_STRING: $PROFILE_STRING"
      ;;

    h)
      hashType=$OPTARG
      echo "hash type: $hashType"
      ;;

    k)
      nKafka=$OPTARG
      echo "number of kafka: $nKafka"
      ;;

    e)
      nReplica=$OPTARG
      echo "number of kafka replication: $nReplica"
      ;;

    z)
      nZoo=$OPTARG
      echo "number of zookeeper: $nZoo"
      ;;
    n)
      nChannel=$OPTARG
      echo "number of channels: $nChannel"
      ;;

    o)
      nOrderer=$OPTARG
      echo "number of orderers: $nOrderer"
      ;;

    p)
      nPeersPerOrg=$OPTARG
      echo "number of peers: $nPeersPerOrg"
      ;;

    r)
      nOrg=$OPTARG
      echo "number of organizations: $nOrg"
      ;;

    s)
      secType=$OPTARG
      echo "security type: $secType"
      ;;

    t)
      ordererType=$OPTARG
      echo "orderer service type: $ordererType"
      ;;

    w)
      HostIP1=$OPTARG
      echo "HostIP1:  $HostIP1"
      ;;

    c)
      batchTimeOut=$OPTARG
      echo "batchTimeOut:  $batchTimeOut"
      ;;

    l)
      peerLogSpec=$OPTARG
      echo "peerLogSpec:  $peerLogSpec"
      ;;

    q)
      ordererLogSpec=$OPTARG
      echo "ordererLogSpec:  $ordererLogSpec"
      ;;

    B)
      batchsizeMaxmessagecount=$OPTARG
      echo "batchsizeMaxmessagecount:  $batchsizeMaxmessagecount"
      ;;

    F)
      MSPDir=$OPTARG
      export MSPDIR=$MSPDir
      echo "MSPDir: $MSPDir"
      ;;

    G)
      SRCMSPDir=$OPTARG
      export SRCMSPDIR=$SRCMSPDir
      echo "SRCMSPDir: $SRCMSPDir"
      ;;

    S)
      TLSEnabled=`echo $OPTARG | tr [A-Z] [a-z]`
      echo "TLSEnabled: $TLSEnabled"
      ;;

    C)
      comName=$OPTARG
      echo "comName: $comName"
      ;;

    M)
      orgMap=$OPTARG
      echo "orgMap: $orgMap"
      ;;

    y)
      yamlF=$OPTARG
      echo "yamlF: $yamlF"
      ;;

    # else
    \?)
      echo "Invalid option: -$OPTARG" >&2
      printHelp
      ;;

    :)
      echo "Option -$OPTARG requires an argument." >&2
      printHelp
      ;;

  esac
done

#first handle network action: up|down
if [ "$networkAction" == "down" ]; then
    ./cleanNetwork.sh $comName
    exit
elif [ "$networkAction" != "up" ]; then
    echo "invalid network action option: $networkAction"
    printHelp
    exit 1
fi

if [ "yamlF" != "none" ]; then
    yamlParser
fi
exit


if [ "$TLSEnabled" == "clientauth" ]; then
    TLSEnabled="enabled"
    MutualTLSEnabled="enabled"
fi
if [ "$TLSEnabled" == "serverauth" ]; then
    TLSEnabled="enabled"
fi

echo "TLSEnabled $TLSEnabled, MutualTLSEnabled $MutualTLSEnabled"

if [ "$ordererType" != "kafka" ]; then
    nKafka=0
    nZoo=0
fi

if [ "$nReplica" -eq 0 ]; then
    nReplica=$nKafka
fi

# input vars
if [ "$ordererType" == "etcdraft" ]; then
    echo " PROFILE_STRING=$PROFILE_STRING, ordererType=$ordererType, nOrderer=$nOrderer"
else
    echo " PROFILE_STRING=$PROFILE_STRING, ordererType=$ordererType, nKafka=$nKafka, nOrderer=$nOrderer, nZoo=$nZoo"
fi
echo " nOrg=$nOrg, nPeersPerOrg=$nPeersPerOrg, ledgerDB=$ledgerDB, hashType=$hashType, secType=$secType, comName=$comName"

CHAN_PROFILE=$PROFILE_STRING"Channel"
ORDERER_PROFILE=$PROFILE_STRING"OrgsOrdererGenesis"
ORG_PROFILE=$PROFILE_STRING"orgschannel"

CWD=$PWD
echo "current working directory: $CWD"
echo "GOPATH=$GOPATH"

if [ ! -z "$orgMap" ]
then
	orgMapParam="-M "$orgMap
fi

echo " "
echo "        ####################################################### "
echo "        #                generate crypto-config.yaml          # "
echo "        ####################################################### "
echo "generate crypto-config.yaml ..."
rm -f crypto-config.yaml
echo "./gen_crypto_cfg.sh -o $nOrderer -r $nOrg -p $nPeersPerOrg -C $comName $orgMapParam"
./gen_crypto_cfg.sh -o $nOrderer -r $nOrg -p $nPeersPerOrg -C $comName $orgMapParam

echo " "
echo "        ####################################################### "
echo "        #                execute cryptogen                    # "
echo "        ####################################################### "
echo "generate crypto ..."
CRYPTOEXE=$BuildDir/cryptogen
CRYPTOCFG=$CWD/crypto-config.yaml
cd $MSPDir
# remove existing crypto-config
rm -rf crypto-config
echo "current working directory: $PWD"
if [ ! -f "$CRYPTOEXE" ]; then
echo "build $CRYPTOEXE "
    cd $FabricDir
    echo "current working directory: $PWD"
    make cryptogen
fi
cd $CWD
echo "current working directory: $PWD"

echo "$CRYPTOEXE generate --output=$MSPDir/crypto-config --config=$CRYPTOCFG"
$CRYPTOEXE generate --output=$MSPDir/crypto-config --config=$CRYPTOCFG

echo " "
echo "        ####################################################### "
echo "        #                 generate configtx.yaml              # "
echo "        ####################################################### "
echo " "
echo "generate configtx.yaml ..."
cd $CWD
echo "current working directory: $PWD"

echo "./gen_configtx_cfg.sh -o $nOrderer -k $nKafka -p $nPeersPerOrg -r $nOrg -h $hashType -s $secType -t $ordererType -f $PROFILE_STRING -w $HostIP1 -C $comName -b $MSPDir/crypto-config -c $batchTimeOut -B $batchsizeMaxmessagecount $orgMapParam"
./gen_configtx_cfg.sh -o $nOrderer -k $nKafka -p $nPeersPerOrg -r $nOrg -h $hashType -s $secType -t $ordererType -f $PROFILE_STRING -w $HostIP1 -C $comName -b $MSPDir/crypto-config -c $batchTimeOut -B $batchsizeMaxmessagecount $orgMapParam

echo " "
echo "        ####################################################### "
echo "        #         create orderer genesis block                # "
echo "        ####################################################### "
echo " "
CFGEXE=$BuildDir/configtxgen
ordererDir=$MSPDir/crypto-config/ordererOrganizations
#cp configtx.yaml $FabricDir"/common/configtx/tool"
#cd $CFGGenDir
if [ ! -f "$CFGEXE" ]; then
    cd $FabricDir
    make configtxgen
fi
#create orderer blocks
cd $CWD
echo "current working directory: $PWD"
ordBlock=$ordererDir/orderer.block
testChannel="testchannel"
echo "$CFGEXE -profile $ORDERER_PROFILE -channelID $testChannel -outputBlock $ordBlock"
$CFGEXE -profile $ORDERER_PROFILE -channelID $testChannel -outputBlock $ordBlock

#create channels configuration transaction
echo " "
echo "        ####################################################### "
echo "        #     create channel configuration transaction        # "
echo "        ####################################################### "
echo " "
for (( i=1; i<=$nChannel; i++ ))
do
    channelTx=$ordererDir"/"$ORG_PROFILE$i".tx"
    echo "$CFGEXE -profile $ORG_PROFILE -channelID $ORG_PROFILE"$i" -outputCreateChannelTx $channelTx"
    $CFGEXE -profile $ORG_PROFILE -channelID $ORG_PROFILE"$i" -outputCreateChannelTx $channelTx
done

#create anchor peer update for org
echo " "
echo "        ####################################################### "
echo "        #         create anchor peer update for orgs          # "
echo "        ####################################################### "
echo " "
for (( j=1; j<=$nChannel; j++ ))
do
    for (( i=1; i<=$nOrg; i++ ))
    do
        orgMSP="PeerOrg"$i
        if [ ! -z "$orgMap" ] && [ -f "$orgMap" ]
        then
            tmpVal=$(jq .$orgMSP $orgMap)
            if [ ! -z "$tmpVal" ] && [ "$tmpVal" != "null" ]
            then
                # Strip quotes from tmpVal if they are present
                if [ "${tmpVal:0:1}" == "\"" ]
                then
                    tmpVal=${tmpVal:1}
                fi
                let "tmpLen = ${#tmpVal} - 1"
                if [ "${tmpVal:$tmpLen:1}" == "\"" ]
                then
                    tmpVal=${tmpVal:0:$tmpLen}
                fi
                orgMSP=$tmpVal
            fi
        fi
        OrgMSP=$ordererDir"/"$testChannel"$j"$orgMSP"anchors.tx"
        echo "$CFGEXE -profile $ORG_PROFILE -outputAnchorPeersUpdate $OrgMSP -channelID $ORG_PROFILE"$j" -asOrg $orgMSP"
        $CFGEXE -profile $ORG_PROFILE -outputAnchorPeersUpdate $OrgMSP -channelID $ORG_PROFILE"$j" -asOrg $orgMSP
    done
done

echo " "
echo "        ####################################################### "
echo "        #                   bring up network                  # "
echo "        ####################################################### "
echo " "
echo "generate docker-compose.yml ..."
echo "current working directory: $PWD"
nPeers=$[ nPeersPerOrg * nOrg ]
echo "number of peers: $nPeers"
echo "./gen_network.sh -a create -x $nCA -p $nPeersPerOrg -r $nOrg -o $nOrderer -k $nKafka -e $nReplica -z $nZoo -t $ordererType -d $ledgerDB -F $MSPDir/crypto-config -G $SRCMSPDir -S $TLSEnabled -m $MutualTLSEnabled -l $peerLogSpec -q $ordererLogSpec $orgMapParam"
./gen_network.sh -a create -x $nCA -p $nPeersPerOrg -r $nOrg -o $nOrderer -k $nKafka -e $nReplica -z $nZoo -t $ordererType -d $ledgerDB -F $MSPDir/crypto-config -G $SRCMSPDir -S $TLSEnabled -m $MutualTLSEnabled -C $comName -l $peerLogSpec -q $ordererLogSpec $orgMapParam

echo " "
echo "        ####################################################### "
echo "        #             generate PTE sc cfg json                # "
echo "        ####################################################### "
echo " "

echo "./gen_PTEcfg.sh -n $nChannel -o $nOrderer -p $nPeersPerOrg -r $nOrg -x $nCA -C $comName -w $HostIP1 -b $MSPDir $orgMapParam"
./gen_PTEcfg.sh -n $nChannel -o $nOrderer -p $nPeersPerOrg -r $nOrg -x $nCA -C $comName -w $HostIP1 -b $MSPDir $orgMapParam
