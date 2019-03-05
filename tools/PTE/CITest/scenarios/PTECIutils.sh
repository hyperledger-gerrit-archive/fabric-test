#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

########## CI test utilits ##########

# common test directories
FabricTestDir=$GOPATH"/src/github.com/hyperledger/fabric-test"
NLDir=$FabricTestDir"/tools/NL"
PTEDir=$FabricTestDir"/tools/PTE"
CMDDir=$PTEDir"/CITest/scripts"
LOGDir=$PTEDir"/CITest/Logs"

# PTEReport()
# purpose: calcuate TPS and latency statistics from PTE generated report
# $1: input pteReport.txt generated from PTE
# $2: output pteReport.txt which the calcuated results will be appended
PTEReport () {

    if [ $# != 2 ]; then
       echo "[PTEReport] Error: invalid arguments number $# "
       exit 1;
    fi

    # save current working directory
    CurrWD=$PWD

    cd $CMDDir
    # calculate overall TPS and output report
    echo
    node get_pteReport.js $1
    cat $1 >> $2

    # restore working directory
    cd $CurrWD
}


# PTE execution loop
# $1: min channel
# $2: max channel
# $3: channel incrment
# $4: min thread
# $5: max thread
# $6: thread increment
# $7: key increment
# $8: key0
# $9: options string
PTEExecLoop () {

    echo "[PTEExecLoop] number of in var=$#"
    myMinChan=$1
    myMaxChan=$2
    myChanIncr=$3
    myMinTh=$4
    myMaxTh=$5
    myThIncr=$6
    myKeyIncr=$7
    myKey0=$8
    args=$9

    echo "[PTEExecLoop] myMinChan=$myMinChan myMaxChan=$myMaxChan myChanIncr=$myChanIncr"
    echo "[PTEExecLoop] myMinTh=$myMinTh myMaxTh=$myMaxTh myThIncr=$myThIncr"
    echo "[PTEExecLoop] args=${args[@]}"

    # channels loop
    for (( myNCHAN = $myMinChan; myNCHAN <= $myMaxChan; myNCHAN+=$myChanIncr )); do
        # threads loop
        for (( myNTHREAD = $myMinTh; myNTHREAD <= $myMaxTh; myNTHREAD+=$myThIncr )); do
            cd $CWD
            set -x
            ./runScaleTraffic.sh --nchan $myNCHAN --nproc $myNTHREAD --keystart $myKey0 ${args[@]}
            CMDResult="$?"
            set +x
            if [ $CMDResult -ne "0" ]; then
                echo "Error: Failed to execute runScaleTraffic.sh"
                exit 1
            fi
            myKey0=$(( myKey0+myKeyIncr ))
        done
    done

}



# PTE execution: 1 org per channel, roundrobin orderer among channels
# PTE execution loop
# $1: num channel
# $2: org number
# $3: key0
# $4: options string
PTEExecOneOrg () {

    echo "[PTEExecLoop] number of in var=$#"
    myChan=$1
    myOrg=$2
    myKey0=$3
    args=$4

    echo "[PTEExecOneOrg] myChan=$myChan myOrg=$myOrg myKey0=$myKey0"
    echo "[PTEExecOneOrg] args=${args[@]}"

    # channels loop
    myNTHREAD=1
    orgPtr=0
    for (( myNCHAN = 1; myNCHAN <= $myChan; myNCHAN+=1 )); do
        # threads loop
        orgPtr=$(( orgPtr % myOrg + 1 ))
        #orgPtr=$(( orgPtr + 1 ))
        myOrgName="org"$orgPtr
        myChanName="testorgschannel"$myNCHAN
            #echo "./runScaleTraffic.sh --name $myChanName --nproc $myNTHREAD --org $myOrgName --keystart $myKey0 ${args[@]}"
            cd $CWD
            set -x
            ./runScaleTraffic.sh --name $myChanName --nproc $myNTHREAD --org $myOrgName --keystart $myKey0 ${args[@]} &
            CMDResult="$?"
            set +x
            if [ $CMDResult -ne "0" ]; then
                echo "Error: Failed to execute runScaleTraffic.sh"
                exit 1
            fi
    done

}

# PTE execution loop Fixed Threads
# PTE execution loop Fixed Threads
# $1: max proc
# $2: key0
# $3: key increment
# $4: options string
PTEExecLoopFixedThreads () {

    echo "[PTEExecLoop] number of in var=$#"
    myMaxProc=$1
    myKey0=$2
    myThIncr=$3
    args=$4
    myHalfProc=$(( myMaxProc / 2 ))

    echo "[PTEExecLoop] myMaxProc=$myMaxProc myKey0=$myKey0 myThIncr=$myThIncr"
    echo "[PTEExecLoop] args=${args[@]}"

    # channels loop
    for (( myNCHAN = 1; myNCHAN <= $myMaxProc; myNCHAN+=1 )); do

        if [ "$myNCHAN" = "$myMaxProc" ]; then
            myNORG=1
        elif [ "$myNCHAN" = "$myHalfProc" ]; then
            myNORG=2
        else
            myNORG=3
        fi

        # threads loop
        for (( myNTHREAD = 1; myNTHREAD <= $myMaxProc; myNTHREAD+=1 )); do
            totalTh=$(( myNCHAN * myNTHREAD * myNORG ))
            if [ "$totalTh" = "$myMaxProc" ]; then

                #echo "./runScaleTraffic.sh --nchan $myNCHAN --norg $myNORG --nproc $myNTHREAD --keystart $myKey0 ${args[@]}"
                cd $CWD
                set -x
                ./runScaleTraffic.sh --nchan $myNCHAN --norg $myNORG --nproc $myNTHREAD --keystart $myKey0 ${args[@]}
                CMDResult="$?"
                set +x
                if [ $CMDResult -ne "0" ]; then
                    echo "Error: Failed to execute runScaleTraffic.sh"
                    exit 1
                fi
                myKey0=$(( myKey0+myKeyIncr ))
            fi
        done
    done

}


# OrdererUpdate
# $1: RAFT base directory, relative to PTE/CITest/scenarios or absolute path
# $2: chanel name, e.g., orderersystemchannel or testorgchannel1
# $3: one orderer IP to retrieve orderer block, e.g., 169.60.99.43
# $4: one orderer name to retrieve orderer block, e.g., orderer1st-ordererorg
# $5: new orderer name, for example, orderer4th-ordererorg
# $6: 
#

OrdererUpdate() {

    RaftBaseDir=$1
    ChannelName=$2
    OrdererIP=$3
    OrdererName=$4
    NewOrderer=$5

    CWD=$PWD
    BINDir=$CWD/$RaftBaseDir/bin
    CFGDir=$CWD/$RaftBaseDir/config

    echo "[$0] RaftBaseDir=$RaftBaseDir, ChannelName=$ChannelName"
    echo "[$0] OrdererIP=$OrdererIP, OrdererName=$OrdererName"
    echo "[$0] NewOrderer=$NewOrderer"
    echo "[$0] BINDir=$BINDir"
    echo "[$0] CFGDir=$CFGDir"

    set -x
    mkdir -p $RaftBaseDir/fabric/configUpdate

    cd $RaftBaseDir/fabric/configUpdate
    rm -rf *
    export CHANNEL_NAME=$ChannelName
    export CORE_PEER_LOCALMSPID="ordererorg"
    export CORE_PEER_MSPCONFIGPATH="$PWD/../keyfiles/ordererorg/users/Admin@ordererorg/msp"
    export CORE_PEER_TLS_ROOTCERT_FILE="$PWD/../keyfiles/ordererorg/orderers/orderer1st-ordererorg.ordererorg/tls/ca.crt"
    export CORE_PEER_ADDRESS=$OrdererName":7050"
    export PATH=$PATH:$BINDir
    export FABRIC_CFG_PATH=$CFGDir
    #sudo su << EOF
    #sudo echo "$OrdererIP $OrdererName" >> /etc/hosts
    #EOF
    #sudo echo "169.60.99.43 orderer1st-ordererorg" >> /etc/hosts
    mkdir -p $PWD/../../config

    #fetch orderer config block
    peer channel fetch config config_block.pb -o $OrdererName:7050 -c $CHANNEL_NAME --tls --cafile $CORE_PEER_TLS_ROOTCERT_FILE

    configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json
    cp config.json modified_config.json


    ## get orderer server cert
    cat ../keyfiles/ordererorg/orderers/$NewOrderer.ordererorg/tls/server.crt | base64 >& certTmp.txt
    ordererCert=`cat certTmp.txt | tr -d '\n'`
    #echo $ordererCert

    ## add new orderer to modified_config.json in consentors section and orderer addresses list
    ##### add new orderer to address list
    jq '.channel_group.values.OrdererAddresses.value.addresses += ["'$NewOrderer':7050"]' modified_config.json >& cfgTmp.json

    ##### add new orderer to consenter list
    jq '.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters += [{"client_tls_cert": "'$ordererCert'", "host": "'$NewOrderer'", "port": "7050", "server_tls_cert": "'$ordererCert'" }]' cfgTmp.json >& modified_config.json


    ## prepare protobuf for update
    configtxlator proto_encode --input config.json --type common.Config --output config.pb
    configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
    configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output addOrderer_update.pb
    configtxlator proto_decode --input addOrderer_update.pb --type common.ConfigUpdate | jq . > addOrderer_update.json
    echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat addOrderer_update.json)'}}}' | jq . > addOrderer_update_in_envelope.json
    configtxlator proto_encode --input addOrderer_update_in_envelope.json --type common.Envelope --output addOrderer_update_in_envelope.pb

    peer channel update -f addOrderer_update_in_envelope.pb -c $CHANNEL_NAME -o orderer1st-ordererorg:7050 --tls --cafile $CORE_PEER_TLS_ROOTCERT_FILE
    set +x

    # return to CWD
    cd $CWD
}

# RemoveOrderer
# $1: RAFT base directory, relative to PTE/CITest/scenarios or absolute path
# $2: chanel name, e.g., orderersystemchannel or testorgchannel1
# $3: one orderer IP to retrieve orderer block, e.g., 169.60.99.43
# $4: one orderer name to retrieve orderer block, e.g., orderer1st-ordererorg
# $5: orderer name for the orderer to remove, for example, orderer4th-ordererorg
RemoveOrderer(){
    RaftBaseDir=$1
    ChannelName=$2
    OrdererIP=$3
    OrdererName=$4
    NewOrderer=$5

    CWD=$PWD
    BINDir=$CWD/$RaftBaseDir/bin
    CFGDir=$CWD/$RaftBaseDir/config

    echo "[$0] RaftBaseDir=$RaftBaseDir, ChannelName=$ChannelName"
    echo "[$0] OrdererIP=$OrdererIP, OrdererName=$OrdererName"
    echo "[$0] OrdererToRemove=$RemoveOrderer"
    echo "[$0] BINDir=$BINDir"
    echo "[$0] CFGDir=$CFGDir"

    set -x
    mkdir -p $RaftBaseDir/fabric/configUpdate

    cd $RaftBaseDir/fabric/configUpdate
    rm -rf *
    export CHANNEL_NAME=$ChannelName
    export CORE_PEER_LOCALMSPID="ordererorg"
    export CORE_PEER_MSPCONFIGPATH="$PWD/../keyfiles/ordererorg/users/Admin@ordererorg/msp"
    export CORE_PEER_TLS_ROOTCERT_FILE="$PWD/../keyfiles/ordererorg/orderers/orderer1st-ordererorg.ordererorg/tls/ca.crt"
    export CORE_PEER_ADDRESS=$OrdererName":7050"
    export PATH=$PATH:$BINDir
    export FABRIC_CFG_PATH=$CFGDir
    #fetch orderer config block
    peer channel fetch config config_block.pb -o $OrdererName:7050 -c $CHANNEL_NAME --tls --cafile $CORE_PEER_TLS_ROOTCERT_FILE

    configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json
    cp config.json modified_config.json


    #Remove orderer data
    jq '.channel_group.values.OrdererAddresses.value.addresses -= ["'$RemoveOrderer':7050"]' modified_config.json >& cfgTmp.json
    for i in $(jq '.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters | keys | .[]' config.json); do
        hostName=$(echo $(jq '.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters['${i}'].host' config.json))
        if [ $hostName = "\"${RemoveOrderer}\"" ]; then
            concenter=$(jq '.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters[0]' config.json)
            jq '.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters -= ['"${concenter}"']' config.json >& cfgTmp.json
        fi
    done

    ## prepare protobuf for update
    configtxlator proto_encode --input config.json --type common.Config --output config.pb
    configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
    configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output removeOrderer_update.pb
    configtxlator proto_decode --input removeOrderer_update.pb --type common.ConfigUpdate | jq . > removeOrderer_update.json
    echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat removeOrderer_update.json)'}}}' | jq . > removeOrderer_update_in_envelope.json
    configtxlator proto_encode --input removeOrderer_update_in_envelope.json --type common.Envelope --output removeOrderer_update_in_envelope.pb

    peer channel update -f removeOrderer_update_in_envelope.pb -c $CHANNEL_NAME -o orderer1st-ordererorg:7050 --tls --cafile $CORE_PEER_TLS_ROOTCERT_FILE
    set +x

    # return to CWD
    cd $CWD

}

# PTE execution nOrderers
# $1: min channel
# $2: max channel
# $3: channel incrment
# $4: min thread
# $5: max thread
# $6: thread increment
# $7: key0
# $8: key increment
# $9: options string
# $10: norderers array
PTEExecNOrderers () {

    echo "[PTEExecLoop] number of in var=$#"
    echo "num in var: $#"
    myMinChan=$1
    shift
    echo "num in var: $#"
    myMaxChan=$1
    shift
    echo "num in var: $#"
    myChanIncr=$1
    shift
    echo "num in var: $#"
    myMinTh=$1
    shift
    echo "num in var: $#"
    myMaxTh=$1
    shift
    echo "num in var: $#"
    myThIncr=$1
    shift
    echo "num in var: $#"
    myKey0=$1
    shift
    echo "num in var: $#"
    myKeyIncr=$1
    shift
    echo "num in var: $#"
    args=$1
    shift
    echo "num in var: $#"
    if [ $# -gt 0 ]; then
        nOrderers=("$@")
    else
        nOrderers=(0)
    fi

    echo "[PTEExecLoop] myMinChan=$myMinChan myMaxChan=$myMaxChan myChanIncr=$myChanIncr"
    echo "[PTEExecLoop] myMinTh=$myMinTh myMaxTh=$myMaxTh myThIncr=$myThIncr"
    echo "[PTEExecLoop] myKey0=$myKey0 myKeyIncr=$myKeyIncr"
    echo "[PTEExecLoop] nOrderers=${nOrderers[@]}"
    echo "[PTEExecLoop] args=${args[@]}"

    ordererList=("orderer1st-ordererorg" "orderer2nd-ordererorg" "orderer3rd-ordererorg" "orderer4th-ordererorg" "orderer5th-ordererorg" \
                 "orderer6th-ordererorg" "orderer7th-ordererorg" "orderer8th-ordererorg" "orderer9th-ordererorg" "orderer10th-ordererorg" \
                 "orderer11th-ordererorg" "orderer12th-ordererorg" "orderer13th-ordererorg" "orderer14th-ordererorg" "orderer15th-ordererorg" \
                 "orderer16th-ordererorg" "orderer17th-ordererorg" "orderer18th-ordererorg" "orderer19th-ordererorg" "orderer20th-ordererorg" \
                 "orderer21st-ordererorg" "orderer22nd-ordererorg" "orderer23rd-ordererorg" "orderer24th-ordererorg" "orderer25th-ordererorg" \
                 "orderer26th-ordererorg" "orderer27th-ordererorg" "orderer28th-ordererorg" "orderer29th-ordererorg" "orderer30th-ordererorg" \
                 "orderer31st-ordererorg" "orderer32nd-ordererorg" "orderer33rd-ordererorg" "orderer34th-ordererorg" "orderer35th-ordererorg" \
                 "orderer36th-ordererorg" )

    # channels loop
    for (( myNCHAN = $myMinChan; myNCHAN <= $myMaxChan; myNCHAN+=$myChanIncr )); do
        # threads loop
        for (( myNTHREAD = $myMinTh; myNTHREAD <= $myMaxTh; myNTHREAD+=$myThIncr )); do
            for (( i=0; i<${#nOrderers[@]}; i++ )); do

                # add orderers to application channel
                if [ "$i" -ne 0 ]; then
                    j=$(( i - 1 ))
                    sOrderer=$(( nOrderers[j] ))
                    eOrderer=$(( nOrderers[i] - 1 ))
                    echo "orderer id ${nOrderers[$i]}: add orderers to application channel: $sOrderer - $eOrderer"
                    for (( k=$sOrderer; k<=$eOrderer; k++ )); do
                        echo "OrdererUpdate raft-quality testorgschannel1 169.60.99.43 orderer1st-ordererorg ${ordererList[$k]}"
                            OrdererUpdate "raft-quality" "testorgschannel1" "169.60.99.43" "orderer1st-ordererorg" ${ordererList[$k]}
                    done
                fi
                #cd $CWD
                #set -x
                echo "./runScaleTraffic.sh --nchan $myNCHAN --nproc $myNTHREAD --norderers ${nOrderers[$i]} --keystart $myKey0 ${args[@]}"
                     #./runScaleTraffic.sh --nchan $myNCHAN --nproc $threadPerOrderer --norderers ${nOrderers[$i]} --keystart $myKey0 ${args[@]}
                #CMDResult="$?"
                #set +x
                #if [ $CMDResult -ne "0" ]; then
                    #echo "Error: Failed to execute runScaleTraffic.sh"
                    #exit 1
                #fi
                myKey0=$(( myKey0+myKeyIncr ))
            done
        done
    done

}
