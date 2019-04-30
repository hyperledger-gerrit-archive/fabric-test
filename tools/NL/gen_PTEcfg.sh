#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

#
# usage: ./gen_PTEcfg.sh [opt] [value]
#

HostIP="localhost"
HostPort=7050
ordererBasePort=5005
CAPort=7054
peerBasePort=7061
peerEventBasePort=6051

function printHelp {
   echo "Usage: "
   echo " ./gen_PTEcfg.sh [opt] [value] "
   echo "    -o: number of orderers, default=1"
   echo "    -p: number of peers per organization, default=1"
   echo "    -r: number of organizations, default=1"
   echo "    -n: number of channels, default=1"
   echo "    -x: number of ca, default=1"
   echo "    -b: MSP directory, default=src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen/crypto-config"
   echo "    -w: host ip, default=localhost"
   echo "    -C: company name, default=example.com"
   echo "    -M: JSON file containing organization and MSP name mappings (optional) "
   echo " "
   echo "Example:"
   echo " ./gen_PTEcfg.sh -n 3 -o 3 -p 2 -r 6 -x 6"
   exit
}


CWD=$PWD

#default vars
nOrderer=1
nOrg=1
nCA=1
nPeersPerOrg=1
nChannel=1
nOrgPerChannel=1
MSPBaseDir="src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen/crypto-config"
ordererBaseDir=$MSPBaseDir"/ordererOrganizations"
peerBaseDir=$MSPBaseDir"/peerOrganizations"
comName="example.com"
orgMap=

while getopts ":o:p:r:n:x:b:w:C:M:" opt; do
  case $opt in
    # number of orderers
    o)
      nOrderer=$OPTARG
      echo "nOrderer:  $nOrderer"
      ;;

    # number of peers per org
    p)
      nPeersPerOrg=$OPTARG
      echo "nPeersPerOrg: $nPeersPerOrg"
      ;;

    # number of org
    r)
      nOrg=$OPTARG
      echo "nOrg:  $nOrg"
      ;;

    # number of channel
    n)
      nChannel=$OPTARG
      echo "number of channels: $nChannel"
      ;;

    # number of ca
    x)
      nCA=$OPTARG
      echo "number of CA: $nCA"
      ;;

    # MSP base dir
    b)
      MSPBaseDir=$OPTARG
      echo "MSPBaseDir:  $MSPBaseDir"
      ;;

    # host IP
    w)
      HostIP=$OPTARG
      echo "HostIP:  $HostIP"
      ;;

    # company name
    C)
      comName=$OPTARG
      echo "comName:  $comName"
      ;;

    # filenames containing organization and MSP names
    M)
      orgMap=$OPTARG
      echo "orgMap: $orgMap"
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


echo "nOrderer=$nOrderer, nPeersPerOrg=$nPeersPerOrg, nOrg=$nOrg, nChannel=$nChannel, nCA=$nCA"
echo "GOPATH: $GOPATH"
if echo "$MSPBaseDir" | grep -q "$GOPATH"; then
    echo "remove gopath from MSPBaseDir"
    prelength=${#GOPATH}
    len1=$[prelength+2]
    len2=${#MSPBaseDir}
    MM=$(echo $MSPBaseDir | cut -c $len1-$len2)
    MSPBaseDir=$MM"/crypto-config"
fi
echo "MSPBaseDir=$MSPBaseDir"
nOrgPerChannel=$nOrg
echo "nOrgPerChannel: $nOrgPerChannel"


# ################  create json
function outOrderer_json {
    adminPath=$ordererBaseDir"/"$comName"/users/Admin@"$comName"/msp"

    lastOrderer=$[nOrderer-1]
    for (( i=0; i<$nOrderer; i++ ))
    do
        ordererid="orderer"$i

        tmp="            \"$ordererid\": {"
        echo "$tmp" >> $scOfile
        tmp="                \"name\": \"OrdererOrg\","
        echo "$tmp" >> $scOfile
        tmp="                \"mspid\": \"OrdererOrg\","
        echo "$tmp" >> $scOfile
        tmp="                \"mspPath\": \"$MSPBaseDir\","
        echo "$tmp" >> $scOfile
        tmp="                \"adminPath\": \"$adminPath\","
        echo "$tmp" >> $scOfile
        tmp="                \"comName\": \"$comName\","
        echo "$tmp" >> $scOfile

        urlPort=$[ordererBasePort+i]
        url="grpcs://"$HostIP":"$urlPort
        tmp="                \"url\": \"$url\","
        echo "$tmp" >> $scOfile

        ordererCom=$ordererid"."$comName
        tmp="                \"server-hostname\": \"$ordererCom\","
        echo "$tmp" >> $scOfile

        ordererTlsCert=$ordererBaseDir"/"$comName"/orderers/"$ordererid"."$comName"/msp/tlscacerts/tlsca."$comName"-cert.pem"
        tmp="                \"tls_cacerts\": \"$ordererTlsCert\""
        echo "$tmp" >> $scOfile

        if [ $i -ne $lastOrderer ]; then
            tmp="            },"
            echo "$tmp" >> $scOfile
        else
            tmp="            }"
            echo "$tmp" >> $scOfile
            if [ $nOrgPerChannel -eq 0 ]; then
                tmp="        }"
            else
                tmp="        },"
            fi
            echo "$tmp" >> $scOfile
        fi
    done
}

function outOrg_json {
    # org/peer
    ordID=0
    caID=0
    for (( i=1; i<=$nOrgPerChannel; i++ ))
    do
        peerid=$i

        orgid="org"$peerid
        if [ ! -z $orgMap ] && [ -f $orgMap ]
        then
            oiVal=$(jq .$orgid $orgMap)
            if [ ! -z $oiVal ] && [ $oiVal != "null" ]
            then
                # Strip quotes from oiVal if they are present
                if [ ${oiVal:0:1} == "\"" ]
                then
                    oiVal=${oiVal:1}
                fi
                let "OILEN = ${#oiVal} - 1"
                if [ ${oiVal:$OILEN:1} == "\"" ]
                then
                    oiVal=${oiVal:0:$OILEN}
                fi
                orgid=$oiVal
            fi
        fi
        adminPath=$peerBaseDir"/"$orgid"."$comName"/users/Admin@"$orgid"."$comName"/msp"
        orgPeer="PeerOrg"$peerid
        if [ ! -z $orgMap ] && [ -f $orgMap ]
        then
            opVal=$(jq .$orgPeer $orgMap)
            if [ ! -z $opVal ] && [ $opVal != "null" ]
            then
                # Strip quotes from opVal if they are present
                if [ ${opVal:0:1} == "\"" ]
                then
                    opVal=${opVal:1}
                fi
                let "OPLEN = ${#opVal} - 1"
                if [ ${opVal:$OPLEN:1} == "\"" ]
                then
                    opVal=${opVal:0:$OPLEN}
                fi
                orgPeer=$opVal
            fi
        fi
        tmp="        \"$orgid\": {"
        echo "$tmp" >> $scOfile

        tmp="                \"name\": \"$orgPeer\","
        echo "$tmp" >> $scOfile
        tmp="                \"mspid\": \"$orgPeer\","
        echo "$tmp" >> $scOfile
        tmp="                \"mspPath\": \"$MSPBaseDir\","
        echo "$tmp" >> $scOfile
        tmp="                \"adminPath\": \"$adminPath\","
        echo "$tmp" >> $scOfile
        tmp="                \"comName\": \"$comName\","
        echo "$tmp" >> $scOfile

        if [ $nOrderer -gt 0 ]; then
            ordID=$(( (n-1) % nOrderer ))
            tmp="                \"ordererID\": \"orderer$ordID\","
            echo "$tmp" >> $scOfile
        else
            echo "Error: no orderer number is specified."
            exit 1
        fi

        if [ $nCA -gt 0 ]; then
            tmp="                \"ca\": {"
            echo "$tmp" >> $scOfile
            caID=$(( caID % nCA ))
            capid=$(( CAPort + caID ))
            caPort="https://"$HostIP":"$capid
            tmp="                    \"url\": \"$caPort\","
            echo "$tmp" >> $scOfile
            caName="ca"$caID
            caID=$(( caID + 1 ))
            tmp="                    \"name\": \"$caName\""
            echo "$tmp" >> $scOfile
            tmp="                },"
            echo "$tmp" >> $scOfile

            tmp="                \"username\": \"admin\","
            echo "$tmp" >> $scOfile
            tmp="                \"secret\": \"adminpw\","
            echo "$tmp" >> $scOfile
        fi


        # peer per org
        for (( j=1; j<=$nPeersPerOrg; j++ ))
        do
            orgCom=$orgid"."$comName
            orgTlscaCert=$peerBaseDir"/"$orgCom"/tlsca/tlsca."$orgCom"-cert.pem"

            j0=$(( j - 1 ))
            peerID="peer"$j
            tmp="                \"$peerID\": {"
            echo "$tmp" >> $scOfile
            peerIP=$(( (i-1)*nPeersPerOrg + j0 + peerBasePort ))
            peerTmp="grpcs://"$HostIP":"$peerIP
            tmp="                    \"requests\": \"$peerTmp\","
            echo "$tmp" >> $scOfile
            eventIP=$(( (i-1)*nPeersPerOrg + j0 + peerEventBasePort ))
            eventTmp="grpcs://"$HostIP":"$eventIP
            tmp="                    \"events\": \"$eventTmp\","
            echo "$tmp" >> $scOfile
            sHost="peer"$j0"."$orgid"."$comName
            tmp="                    \"server-hostname\": \"$sHost\","
            echo "$tmp" >> $scOfile
            tmp="                    \"tls_cacerts\": \"$orgTlscaCert\""
            echo "$tmp" >> $scOfile

            if [ $j -ne $nPeersPerOrg ]; then
                tmp="                },"
                echo "$tmp" >> $scOfile
            else
                tmp="                }"
                echo "$tmp" >> $scOfile
            fi
        done

        if [ $i -ne $nOrgPerChannel ]; then
            tmp="        },"
            echo "$tmp" >> $scOfile
        else
            tmp="        }"
            echo "$tmp" >> $scOfile
        fi
    done

    tmp="    }"
    echo "$tmp" >> $scOfile

}

#begin process: create json
for (( n=1; n<=$nChannel; n++ ))
do
    scOfile="config-chan"$n"-TLS.json"
    if [ -e $scOfile ]; then
        rm -f $scOfile
    fi

    ## header
    tmp="{"
    echo "$tmp" >> $scOfile
    tmp="    \"test-network\": {"
    echo "$tmp" >> $scOfile
    tmp="        \"gopath\": \"GOPATH\","
    echo "$tmp" >> $scOfile

    ## orderers
    tmp="        \"orderer\": {"
    echo "$tmp" >> $scOfile

    ## orderers
    outOrderer_json

    ## orgs with peers
    if [ $nOrgPerChannel -eq 0 ]; then
        tmp="    }"
        echo "$tmp" >> $scOfile
    else
        outOrg_json
    fi

    tmp="}"
    echo "$tmp" >> $scOfile
done

# ################  create yaml
function outOrderer_yaml {
    adminPath=$ordererBaseDir"/"$comName"/users/Admin@"$comName"/msp"

    lastOrderer=$[nOrderer-1]
    for (( i=0; i<$nOrderer; i++ ))
    do
        ordererid="orderer"$i

        tmp="    $ordererid:"
        echo "$tmp" >> $scOfile
        tmp="      name: OrdererOrg"
        echo "$tmp" >> $scOfile
        tmp="      mspid: OrdererOrg"
        echo "$tmp" >> $scOfile
        tmp="      mspPath: $MSPBaseDir"
        echo "$tmp" >> $scOfile
        tmp="      adminPath: $adminPath"
        echo "$tmp" >> $scOfile
        tmp="      comName: $comName"
        echo "$tmp" >> $scOfile

        urlPort=$[ordererBasePort+i]
        url="grpcs://"$HostIP":"$urlPort
        tmp="      url: $url"
        echo "$tmp" >> $scOfile

        ordererCom=$ordererid"."$comName
        tmp="      server-hostname: $ordererCom"
        echo "$tmp" >> $scOfile

        ordererTlsCert=$ordererBaseDir"/"$comName"/orderers/"$ordererid"."$comName"/msp/tlscacerts/tlsca."$comName"-cert.pem"
        tmp="      tls_cacerts: $ordererTlsCert"
        echo "$tmp" >> $scOfile

    done
}

function outOrg_yaml {
    # org/peer
    ordID=0
    caID=0
    for (( i=1; i<=$nOrgPerChannel; i++ ))
    do
        peerid=$i

        orgid="org"$peerid
        if [ ! -z $orgMap ] && [ -f $orgMap ]
        then
            oiVal=$(jq .$orgid $orgMap)
            if [ ! -z $oiVal ] && [ $oiVal != "null" ]
            then
                # Strip quotes from oiVal if they are present
                if [ ${oiVal:0:1} == "\"" ]
                then
                    oiVal=${oiVal:1}
                fi
                let "OILEN = ${#oiVal} - 1"
                if [ ${oiVal:$OILEN:1} == "\"" ]
                then
                    oiVal=${oiVal:0:$OILEN}
                fi
                orgid=$oiVal
            fi
        fi
        adminPath=$peerBaseDir"/"$orgid"."$comName"/users/Admin@"$orgid"."$comName"/msp"
        orgPeer="PeerOrg"$peerid
        if [ ! -z $orgMap ] && [ -f $orgMap ]
        then
            opVal=$(jq .$orgPeer $orgMap)
            if [ ! -z $opVal ] && [ $opVal != "null" ]
            then
                # Strip quotes from opVal if they are present
                if [ ${opVal:0:1} == "\"" ]
                then
                    opVal=${opVal:1}
                fi
                let "OPLEN = ${#opVal} - 1"
                if [ ${opVal:$OPLEN:1} == "\"" ]
                then
                    opVal=${opVal:0:$OPLEN}
                fi
                orgPeer=$opVal
            fi
        fi
        tmp="  $orgid:"
        echo "$tmp" >> $scOfile


        tmp="    name: $orgPeer"
        echo "$tmp" >> $scOfile
        tmp="    mspid: $orgPeer"
        echo "$tmp" >> $scOfile
        tmp="    mspPath: $MSPBaseDir"
        echo "$tmp" >> $scOfile
        tmp="    adminPath: $adminPath"
        echo "$tmp" >> $scOfile
        tmp="    comName: $comName"
        echo "$tmp" >> $scOfile

        if [ $nOrderer -gt 0 ]; then
            ordID=$(( (n-1) % nOrderer ))
            tmp="    ordererID: orderer$ordID"
            echo "$tmp" >> $scOfile
        else
            echo "Error: no orderer number is specified."
            exit 1
        fi

        if [ $nCA -gt 0 ]; then
            tmp="    ca:"
            echo "$tmp" >> $scOfile
            caID=$(( caID % nCA ))
            capid=$(( CAPort + caID ))
            caPort="https://"$HostIP":"$capid
            tmp="      url: $caPort"
            echo "$tmp" >> $scOfile
            caName="ca"$caID
            caID=$(( caID + 1 ))
            tmp="      name: $caName"
            echo "$tmp" >> $scOfile

            tmp="    username: admin"
            echo "$tmp" >> $scOfile
            tmp="    secret: adminpw"
            echo "$tmp" >> $scOfile
        fi


        # peer per org
        for (( j=1; j<=$nPeersPerOrg; j++ ))
        do
            orgCom=$orgid"."$comName
            orgTlscaCert=$peerBaseDir"/"$orgCom"/tlsca/tlsca."$orgCom"-cert.pem"

            j0=$(( j - 1 ))
            peerID="peer"$j
            tmp="    $peerID:"
            echo "$tmp" >> $scOfile
            peerIP=$(( (i-1)*nPeersPerOrg + j0 + peerBasePort ))
            peerTmp="grpcs://"$HostIP":"$peerIP
            tmp="      requests: $peerTmp"
            echo "$tmp" >> $scOfile
            eventIP=$(( (i-1)*nPeersPerOrg + j0 + peerEventBasePort ))
            eventTmp="grpcs://"$HostIP":"$eventIP
            tmp="      events: $eventTmp"
            echo "$tmp" >> $scOfile
            sHost="peer"$j0"."$orgid"."$comName
            tmp="      server-hostname: $sHost"
            echo "$tmp" >> $scOfile
            tmp="      tls_cacerts: $orgTlscaCert"
            echo "$tmp" >> $scOfile

        done

    done

}

#begin process
for (( n=1; n<=$nChannel; n++ ))
do
    scOfile="config-chan"$n"-TLS.yaml"
    if [ -e $scOfile ]; then
        rm -f $scOfile
    fi

    ## header
    tmp="# Copyright IBM Corp. All Rights Reserved."
    echo "$tmp" >> $scOfile
    tmp="#"
    echo "$tmp" >> $scOfile
    tmp="# SPDX-License-Identifier: Apache-2.0"
    echo "$tmp" >> $scOfile
    tmp="---"
    echo "$tmp" >> $scOfile
    tmp="test-network:"
    echo "$tmp" >> $scOfile
    tmp="  gopath: GOPATH"
    echo "$tmp" >> $scOfile

    ## orderers
    tmp="  orderer:"
    echo "$tmp" >> $scOfile

    ## orderers
    outOrderer_yaml

    ## orgs with peers
    if [ $nOrgPerChannel -ne 0 ]; then
        outOrg_yaml
    fi

done


exit

