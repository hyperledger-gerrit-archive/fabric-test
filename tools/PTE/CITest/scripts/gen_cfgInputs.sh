#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# The script executes multiple chaincodes on multiple network using PTE.
# The execution include:
# create/join channels, install/instantiate chaincodes, execute transactions

# FUNCTION: usage
#           Displays usage command line options; examples; exits.
usage () {
    echo -e "\nUSAGE:\t./gen_cfgInputs.sh -d <serv_cred_dir> [options] [values]"
    echo -e "requirement: a directory contains all service credential files in PTE dir"
    echo -e "             this directory is to be specified with -d option"
    echo
    echo -e "-h, --help\tView this help message"

    echo -e "-n, --name\tblank-separated list of channels"
    echo -e "\t\t(Default: defaultchannel. Note: cannot be used with --nchan)"

    echo -e "--nchan \tnumber of channels"
    echo -e "\t\t(Default: 0. Note: cannot be used with -n nor --name)"

    echo -e "--chanprefix\tchannel name prefix, used with option --nchan"
    echo -e "\t\t(Default: defaultchannel)"

    echo -e "-c, --channel\tcreate/join channel"
    echo -e "\t\t(Default: No)"

    echo -e "-o, --org\tblank-separated list of organizations"
    echo -e "\t\t(Default: None. Note: cannot be used with --norg)"

    echo -e "--norg  \tnumber of organization"
    echo -e "\t\t(Default: 0. Note: cannot be used with -o nor --org)"

    echo -e "--orgprefix\torg name prefix"
    echo -e "\t\t(Default: org. Note: used with option --norg)"

    echo -e "-i, --install\tinstall/instantiate chaincode"
    echo -e "\t\t(Default: No)"

    echo -e "-a, --app\tblank-separated list of chaincodes, [samplecc|samplejs|samplejava|marbles02]"
    echo -e "\t\t(Default: None)"

    echo -e "-d, --scdir\tservice credential files directory"
    echo -e "\t\t(Default: None. This parameter is required.)"

    echo -e "-p, --prime\texecute query to sych-up ledger, [YES|NO]"
    echo -e "\t\t(Default: No)"

    echo -e "--txmode\ttransaction mode, [Latency|Constant|Mix]"
    echo -e "\t\t(Default: Constant)"

    echo -e "-t, --tx\ttransaction type, [MOVE|QUERY]"
    echo -e "\t\t(Default: None)"

    echo -e "--nproc \tnumber of proc per org [integer]"
    echo -e "\t\t(Default: 1)"

    echo -e "--nreq  \tnumber of transactions [integer]"
    echo -e "\t\t(Default: 1000)"

    echo -e "--freq  \ttransaction frequency [unit: ms]"
    echo -e "\t\t(Default: 0)"

    echo -e "--rundur\tduration of execution [unit: sec]"
    echo -e "\t\t(Default: 0)"

    echo -e "--keystart\ttransaction starting key [integer]"
    echo -e "\t\t(Default: 0)"

    echo -e "--targetpeers\ttransaction target peers [ORGANCHOR|ALLANCHORS|ORGPEERS|ALLPEERS|DISCOVERY]"
    echo -e "\t\t(Default: ORGANCHOR)"

    echo -e "--chkpeers\tinvoke check target peers [ORGANCHOR|ALLANCHORS|ORGPEERS|ALLPEERS|DISCOVERY]"
    echo -e "\t\t(Default: ORGANCHOR)"

    echo -e "--chktx \tinvoke check transaction [LAST|ALL]"
    echo -e "\t\t(Default: LAST)"

    echo -e "--chktxnum\tinvoke check transactions number [integer]"
    echo -e "\t\t(Default: 1)"

    echo -e "--targetorderers\ttransaction target orderer [UserDefined|RoundRobin]"
    echo -e "\t\t(Default: UserDefined)"

    echo -e "--evttimeout \tevent timeout [unit: ms]"
    echo -e "\t\t(Default: 3600000)"

    echo -e "--treqtimeout \trequest ack timeout [unit: ms]"
    echo -e "\t\t(Default: 600000)"

    echo -e "--tgrpctimeout \tgrpc wait timeout [unit: ms]"
    echo -e "\t\t(Default: 600000)"

    echo -e "examples:"
    echo -e "./gen_cfgInputs.sh -d SCDir -n testorgschannel1 testorgschannel2 --org org1 org2 -c"
    echo -e "./gen_cfgInputs.sh -d SCDir --nchan 3 --chanprefix testorgschannel --org org1 org2 -a samplecc -c -i"
    echo -e "./gen_cfgInputs.sh -d SCDir --nchan 3 --chanprefix testorgschannel --norg 2 -a marbles02 samplecc -i"
    echo -e "./gen_cfgInputs.sh -d SCDir -n testorgschannel1 --norg 2 -a samplecc samplejs marbles02 -p -t Move -i"
    echo -e "./gen_cfgInputs.sh -d SCDir -n testorgschannel1 --norg 2 --orgprefix testorg -a samplecc samplejs marbles02 -p -t Move -i"
    echo -e "./gen_cfgInputs.sh -d SCDir -n testorgschannel1 testorgschannel2 --norg 2 -a samplejava -i -t Move"
    echo -e "./gen_cfgInputs.sh -d SCDir -n testorgschannel1 --norg 2 --orgprefix org -a samplejava samplejs --freq 10 --rundur 50 --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t move"
    echo -e "./gen_cfgInputs.sh -d SCDir -n testorgschannel1 --norg 2 -a samplecc --freq 10 --nreq 1000 --nproc 1 --keystart 100 --targetpeers ORGANCHOR --chkpeers ORGANCHOR -t move"
    echo -e "./gen_cfgInputs.sh -d SCDir --nchan 3 --chanprefix testorgschannel --norg 2 -a samplecc --freq 10 --rundur 50 --nproc 1 --keystart 100 --targetpeers ORGANCHOR --targetorderers RoundRobin --chkpeers ORGANCHOR -t move"
    echo
    exit
}


## printVar(): print input vars
printVars () {

echo
echo
echo "*********************************************************"
echo "***                                                      "
echo "***                   input parameters                   "
echo "***                                                      "
echo "***  service credential file directory                   "
echo "***      SCDIR: $SCDIR                                   "
echo "***                                                      "
echo "***  chaincodes                                          "
echo "***      number: ${#Chaincode[@]}                        "
echo "***      Chaincode: ${Chaincode[@]}                      "
echo "***                                                      "
echo "***  processes parameters                                "
echo "***      TXProc: $TXType                                 "
echo "***      PrimeProc: $PrimeProc                           "
echo "***      CCProc: $CCProc                                 "
echo "***      ChanProc: $ChanProc                             "
echo "***                                                      "
echo "***  network parameters                                  "
echo "***      CHANNEL set name: $setChanName                  "
echo "***      CHANNEL set num: $setChanNum                    "
echo "***      NCHAN: $NCHAN                                   "
echo "***      CHANPREFIX: $CHANPREFIX                         "
echo "***      CHANNEL length: ${#CHANNEL[@]}                  "
echo "***      CHANNEL: ${CHANNEL[@]}                          "
echo "***                                                      "
echo "***      ORGS set name: $setOrgName                      "
echo "***      ORGS set num: $setOrgNum                        "
echo "***      NORG: $NORG                                     "
echo "***      ORGPREFIX: $ORGPREFIX                           "
echo "***      ORGS length: ${#ORGS[@]}                        "
echo "***      ORGS: ${ORGS[@]}                                "
echo "***                                                      "
echo "***  transaction parameters                              "
echo "***      NPROC: $NPROC                                   "
echo "***      NREQ: $NREQ                                     "
echo "***      TXType: $TXType                                 "
echo "***      TXMODE: $TXMODE                                 "
echo "***      FREQ: $FREQ ms                                  "
echo "***      TARGETPEERS: $TARGETPEERS                       "
echo "***      TARGETORDERERS: $TARGETORDERERS                 "
echo "***      RUNDUR: $RUNDUR sec                             "
echo "***      KEYSTART: $KEYSTART                             "
echo "***      EVENT TIMEOUT: $EVTTIMEOUT ms                   "
echo "***      REQUEST TIMEOUT: $REQTIMEOUT ms                 "
echo "***      GRPC WAIT TIMEOUT: $GRPCTIMEOUT ms              "
echo "***                                                      "
echo "***  validation parameters                               "
echo "***      CHKPEERS: $CHKPEERS                             "
echo "***      CHKTX: $CHKTX                                   "
echo "***      CHKTXNUM: $CHKTXNUM                             "
echo "***                                                      "
echo "*********************************************************"

}

# FUNCTION: error
#           Displays error message; exits.
#     ARGS: 1: error message
error () {
    # 1: error message
    echo -e "\nERROR: $1"
    exit
}


CWD=$PWD
cd ../..
PTEDIR=$PWD
TEMPLATEDIR=$PTEDIR/CITest/scripts/cfgTemplates
runDir=$PTEDIR/runPTE

CHANNEL="defaultchannel"       # channel name
ChanProc="NO"
CCProc="NO"
PrimeProc="NO"
TXType=""
Chaincode=""
SCDIR=""
setOrgName="no"
setOrgNum="no"
ORGS=""
ORGPREFIX="org"                # default org name

setChanName="no"
setChanNum="no"
CHANPREFIX="defaultchannel"    # default channel name
NCHAN=0
NORG=0
TXMODE="Constant"
NPROC=1
FREQ=0
NREQ=1000
RUNDUR=0
KEYSTART=0
TARGETPEERS="ORGANCHOR"
CHKPEERS="ORGANCHOR"
CHKTX="LAST"
CHKTXNUM=1
TARGETORDERERS="UserDefined"
EVTTIMEOUT=3600000
REQTIMEOUT=600000
GRPCTIMEOUT=600000

# chaincode path
CCPathsamplecc="github.com/hyperledger/fabric-test/chaincodes/samplecc/go"
CCPathsamplecc="${CCPathsamplecc//\//\\/}"
CCPathsamplejs="github.com/hyperledger/fabric-test/chaincodes/samplecc/node"
CCPathsamplejs="${CCPathsamplejs//\//\\/}"
CCPathsamplejava="github.com/hyperledger/fabric-test/chaincodes/samplecc/java"
CCPathsamplejava="${CCPathsamplejava//\//\\/}"
CCPathmarbles02="github.com/hyperledger/fabric-test/fabric/examples/chaincode/go/marbles02"
CCPathmarbles02="${CCPathmarbles02//\//\\/}"
MatadataPath="github.com/hyperledger/fabric-test/fabric/examples/chaincode/go/marbles02/META-INF"
MatadataPath="${MatadataPath//\//\\/}"
LANGUAGE="golang"
CCPath=""
MDPath=""

# get chaincode path
# $1: chaincode
getCCPath() {
    cc=$1
    if [ $cc == "samplecc" ]; then
        CCPath=$CCPathsamplecc
        LANGUAGE="golang"
    elif [ $cc == "samplejs" ]; then
        CCPath=$CCPathsamplejs
        LANGUAGE="node"
    elif [ $cc == "samplejava" ]; then
        CCPath=$CCPathsamplejava
        LANGUAGE="java"
    elif [ $cc == "marbles02" ]; then
        CCPath=$CCPathmarbles02
        MDPath=$MatadataPath
        LANGUAGE="golang"
    fi
}


# insert org into template
InsertOrgs() {
    InJson=$1
    echo -e "PWD $PWD, process $InJson\n"
        preOrg="orgName"
        i=1
    if [ $NORG -gt 0 ]; then
        while [ $i -le $NORG ]
        do
            #echo -e "i=$i, ORGS length=$NORG"
            if [ $i -eq $NORG ]; then
                sed -i -e "/\"$preOrg\"/a \            \"org$i\"" $InJson
            else
                sed -i -e "/\"$preOrg\"/a \            \"org$i\"," $InJson
            fi
            # Remove backup files; cleanup is needed when running on the mac (freebsd), where
            # a backup file would be created by the -i option; refer to FAB-12629 comments.
            rm -f $InJson"-e"
            preOrg="org"$i
            ((i++))
        done
    else
        for org in "${ORGS[@]}"; do
            #echo -e "i=$i, ORGS length=${#ORGS[@]}"
            if [ $i -eq ${#ORGS[@]} ]; then
                sed -i -e "/\"$preOrg\"/a \            \"$org\"" $InJson
            else
                sed -i -e "/\"$preOrg\"/a \            \"$org\"," $InJson
            fi
            rm -f $InJson"-e"
            ((i++))
            preOrg=$org
        done
    fi
}

# create PTE input json: create/join channel and install/instantiate chaincode
# $1: config file name
# $2: SC file
# $3: channel
# $4: chaincode (optional)
PreCFGProc() {

    cfgName=$1
    sc=$2
    chnl=$3
    echo -e " $0: sfile=$sc $chnl=$chnl"
    if [ $# -eq 4 ]; then
        cc=$4
        echo -e " $0: chaincode=$cc"
    else
        cc=""
    fi
        sed -i -e "s/_CHANNELNAME_/$chnl/g" $cfgName
        sed -i -e "s/_CHANNELID_/$chnl/g" $cfgName
        sed -i -e "s/_SCDIRECTORY_/$SCDIR/g" $cfgName
        sed -i -e "s/_SCFILENAME_/$sc/g" $cfgName
        sed -i -e "s/_CHAINCODEPATH_/$CCPath/g" $cfgName
        sed -i -e "s/_CHAINCODEID_/$cc/g" $cfgName
        sed -i -e "s/_LANGUAGE_/$LANGUAGE/g" $cfgName
        if [ "$MDPath" == "" ]; then
            sed -i -e "s/metadataPath/unused/g" $cfgName
        else
            sed -i -e "s/_METADATAPATH_/$MDPath/g" $cfgName
        fi
        rm -f $cfgName"-e"

        InsertOrgs $cfgName

}

# create PTE input json: transaction
# $1: cfg json
# $2: invoke type
PreTXProc() {

    cfgTX=${1}
    invokeType=${2}

        sed -i -e "s/_INVOKETYPE_/$invokeType/g" $cfgTX
        sed -i -e "s/_NPROC_/$NPROC/g" $cfgTX
        sed -i -e "s/_FREQ_/$FREQ/g" $cfgTX
        sed -i -e "s/_NREQ_/$NREQ/g" $cfgTX
        sed -i -e "s/_RUNDUR_/$RUNDUR/g" $cfgTX
        sed -i -e "s/_TRANSMODE_/$TXMODE/g" $cfgTX
        sed -i -e "s/_TARGETPEERS_/$TARGETPEERS/g" $cfgTX
        sed -i -e "s/_CHKPEERS_/$CHKPEERS/g" $cfgTX
        sed -i -e "s/_CHKTX_/$CHKTX/g" $cfgTX
        sed -i -e "s/_CHKTXNUM_/$CHKTXNUM/g" $cfgTX
        sed -i -e "s/_TARGETORDERERS_/$TARGETORDERERS/g" $cfgTX
        sed -i -e "s/_EVTTIMEOUT_/$EVTTIMEOUT/g" $cfgTX
        sed -i -e "s/_REQTIMEOUT_/$REQTIMEOUT/g" $cfgTX
        sed -i -e "s/_GRPCTIMEOUT_/$GRPCTIMEOUT/g" $cfgTX
        rm -f $cfgTX"-e"
}

# channel process: create and join
ChannelProc() {
    # loop on channel list
    for chan in "${CHANNEL[@]}"; do
        # loop on network list
        for scfile in "${NWName[@]}"; do
            fname=$scfile"_"$chan
            cd $runDir
            echo "process cc $scfile channel $chan"

            cfgCREATE=create-$fname".json"
            cp $TEMPLATEDIR/template-create.json $cfgCREATE

            PreCFGProc $cfgCREATE $scfile.json $chan

            # create channel
            runCaseCreate=runCases-create-$fname".txt"
            tmp=$runDir/$cfgCREATE
            echo "sdk=node $tmp" >> $runCaseCreate

            cd $PTEDIR
            echo "create channel on $scfile"
            ./pte_driver.sh $runDir/$runCaseCreate

            sleep 15
            # join channel
            cd $runDir

            cfgJOIN=join-$fname".json"
            cp $TEMPLATEDIR/template-join.json $cfgJOIN

            PreCFGProc $cfgJOIN $scfile.json $chan

            runCaseJoin=runCases-join-$fname".txt"
            tmp=$runDir/$cfgJOIN
            echo "sdk=node $tmp" >> $runCaseJoin

            cd $PTEDIR
            echo "join channel on $scfile"
            ./pte_driver.sh $runDir/$runCaseJoin
            cd $runDir
        done     # end loop on network list
    done         # end loop on channel list
}

# install/instantiate chaincode
ChaincodeProc() {
    # loop on chaincode list
    for chaincode in "${Chaincode[@]}"; do
        getCCPath $chaincode

        # loop on network list
        for scfile in "${NWName[@]}"; do
            # loop on channel list
            for chan in "${CHANNEL[@]}"; do
                cd $runDir
                echo "[$0] process cc $scfile"
                echo "[$0] CCPath $CCPath"
                sc=$scfile".json"
                echo "[$0] sc $sc"

                fname=$scfile"_"$chan"-"$chaincode
                cfgINSTALL=install-$fname".json"
                cp $TEMPLATEDIR/template-install.json $cfgINSTALL

                PreCFGProc $cfgINSTALL $scfile.json $chan $chaincode

                # install chaincode
                runCaseinstall=runCases-install-$fname".txt"
                tmp=$runDir/$cfgINSTALL
                echo "sdk=node $tmp" >> $runCaseinstall

                # instantiate chaincode

                cfgINSTAN=instantiate-$fname".json"
                cp $TEMPLATEDIR/template-instantiate.json $cfgINSTAN

                PreCFGProc $cfgINSTAN $scfile.json $chan $chaincode

                runCaseinstantiate=runCases-instantiate-$fname".txt"
                tmp=$runDir/$cfgINSTAN
                echo "sdk=node $tmp" >> $runCaseinstantiate

                cd $PTEDIR
                echo "install chaincode on $scfile"
                echo "./pte_driver.sh $runDir/$runCaseinstall"
                ./pte_driver.sh $runDir/$runCaseinstall

                echo "instantiate chaincode on $scfile"
                echo "./pte_driver.sh $runDir/$runCaseinstantiate"
                ./pte_driver.sh $runDir/$runCaseinstantiate
                cd $runDir

            done     # end loop on channel list
        done         # end loop on network list
    done             # end loop on chaincode list
}


TransactionProc() {
    echo "[TransactionProc: $1  $Chaincode]"

    INVOKETYPE=$1

    # execute transactions
    PTEMgr=$runDir/PTEMgr-runTX.txt
    # loop on chaincode list
    for chaincode in "${Chaincode[@]}"; do
        getCCPath $chaincode
        # loop on network list
        for scfile in "${NWName[@]}"; do
            # loop on channel list
            for chan in "${CHANNEL[@]}"; do

                echo "process $chaincode tx on $scfile"
                fname=$scfile"_"$chan"-"$chaincode
                cd $runDir

                pteCfgTX="TX-"$fname".json"
                pteTXopt="TXopt.json"

                cp $TEMPLATEDIR/template-tx.json $pteCfgTX
                cp $TEMPLATEDIR/txCfgOpt.json $pteTXopt
                if [ ! -e $ccDfnOpt.json ]; then
                    echo -e "copy $chaincode DfnOpt.json"
                    cp $TEMPLATEDIR/$chaincode"DfnOpt.json" $runDir
                    sed -i -e "s/_KEYSTART_/$KEYSTART/g" $chaincode"DfnOpt.json"
                    rm -f $chaincode"DfnOpt.json-e"
                fi

                # create PTE transaction configuration input json
                PreCFGProc $pteCfgTX $scfile.json $chan $chaincode
                PreTXProc $pteTXopt $INVOKETYPE

                runCaseTX=runCasesTX-$fname".txt"
                tmp=$runDir/$pteCfgTX
                echo "sdk=node $tmp"
                echo "sdk=node $tmp" >> $runCaseTX
                echo "driver=pte $runDir/$runCaseTX" >> $PTEMgr

            done
        done
    done

    cd $PTEDIR
    echo "---- current dir: $PTEDIR, executing $PTEMgr"
    ./pte_mgr.sh $PTEMgr

}


# GET CUSTOM OPTIONS
echo -e "\nAny optional arguments chosen:\n"
while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in

      -h | --help)
          usage        # displays usage info; exits
          ;;

      -d | --scdir)
          shift
          SCDIR=$1     # service credential directory
          echo -e "\t- Specify SCDIR: $SCDIR\n"
          TT=`ls $SCDIR`
          i=0
          for nw in $TT; do
              fext=`echo "$nw" | cut -d'.' -f2`
              if [ $fext == 'json' ]; then
                 SCFILES[$i]=$nw
                 NWName[$i]=`echo "$nw" | cut -d'.' -f1`
                 i=$[ i + 1]
              fi
          done
          echo -e "\t- Specify SCFILES: ${SCFILES[@]}"
          echo -e "\t- Specify SCFILES: ${NWName[@]}"

          shift
          ;;

      -n | --name)
          if [ $setChanNum == "yes" ]; then
              echo "Error: cannot use option $1 with option --nchan"
              usage
          fi
          setChanName="yes"
          shift
          i=0
          CHANNEL[$i]=$1  # Channels
          shift
          until [[ $(eval "echo \$1") =~ ^-.* ]] || [ -z $(eval "echo \$1") ]; do
              i=$[ i + 1]
              CHANNEL[$i]=$1
              shift
          done
          echo -e "\t- Specify Channels: ${CHANNEL[@]}"
          echo -e ""
          ;;

      --nchan)
          if [ $setChanName == "yes" ]; then
              echo "Error: cannot use option $1 with option -n or --name"
              usage
          fi
          setChanNum="yes"
          shift
          NCHAN=$1           # number of channels
          echo -e "\t- Specify number of channels: $NCHAN\n"
          shift
          ;;

      --chanprefix)
          shift
          CHANPREFIX=$1      # channel name prefix
          echo -e "\t- Specify channel name prefix: $CHANPREFIX\n"
          shift
          ;;

      -o | --org)
          if [ $setOrgNum == "yes" ]; then
              echo "Error: cannot use option $1 with option --norg"
              usage
          fi
          setOrgName="yes"
          shift
          i=0
          ORGS[$i]=$1  # organization
          shift
          until [[ $(eval "echo \$1") =~ ^-.* ]] || [ -z $(eval "echo \$1") ]; do
              i=$[ i + 1]
              ORGS[$i]=$1
              shift
          done
          echo -e "\t- Specify Channels: ${ORGS[@]}"
          echo -e ""
          ;;

      --norg)
          if [ $setOrgName == "yes" ]; then
              echo "Error: cannot use option $1 with option -o or --org"
              usage
          fi
          setOrgNum="yes"
          shift
          NORG=$1           # number of organization
          echo -e "\t- Specify number of org: $NORG\n"
          shift
          ;;

      --orgprefix)
          shift
          ORGPREFIX=$1      # org name prefix
          echo -e "\t- Specify org name prefix: $ORGPREFIX\n"
          shift
          ;;

      -a | --app)
          shift
          i=0
          Chaincode[$i]=$1  # Chaincodes
          shift
          until [[ $(eval "echo \$1") =~ ^-.* ]] || [ -z $(eval "echo \$1") ]; do
              i=$[ i + 1]
              Chaincode[$i]=$1
              shift
          done
          echo -e "\t- Specify Chaincodes: ${Chaincode[@]}"
          echo -e ""
          ;;

      -c | --channel)
          ChanProc="YES"
          echo -e "\t- Specify create/join channel: $ChanProc\n"
          shift
          ;;

      -i | --install)
          CCProc="YES"
          echo -e "\t- Specify install/instantiate chaincode: $CCProc\n"
          shift
          ;;

      -p | --prime)
          PrimeProc="YES"
          echo -e "\t- Specify prime: $PrimeProc\n"
          shift
          ;;

      -t | --tx)
          shift
          TXType=$1
          echo -e "\t- Specify transaction: $TXType\n"
          shift
          ;;

      --txmode)
          shift
          TXMODE=$1
          echo -e "\t- Specify number of transactions: $NREQ\n"
          shift
          ;;

      --nproc)
          shift
          NPROC=$1
          echo -e "\t- Specify number of proc: $NPROC\n"
          shift
          ;;

      --nreq)
          shift
          NREQ=$1
          echo -e "\t- Specify number of transactions: $NREQ\n"
          shift
          ;;

      --rundur)
          shift
          RUNDUR=$1
          echo -e "\t- Specify duration of execution: $RUNDUR\n"
          shift
          ;;

      --freq)
          shift
          FREQ=$1
          echo -e "\t- Specify transaction rate: $FREQ\n"
          shift
          ;;

      --keystart)
          shift
          KEYSTART=$1
          echo -e "\t- Specify transaction start key: $KEYSTART\n"
          shift
          ;;

      --targetpeers)
          shift
          TARGETPEERS=$1
          echo -e "\t- Specify transaction target peers: $TARGETPEERS\n"
          shift
          ;;

      --chkpeers)
          shift
          CHKPEERS=$1
          echo -e "\t- Specify invoke check peers: $CHKPEERS\n"
          shift
          ;;

      --chktx)
          shift
          CHKTX=$1
          echo -e "\t- Specify invoke check transaction: $CHKTX\n"
          shift
          ;;

      --chktxnum)
          shift
          CHKTXNUM=$1
          echo -e "\t- Specify invoke check transaction number: $CHKTXNUM\n"
          shift
          ;;

      --targetorderers)
          shift
          TARGETORDERERS=$1
          echo -e "\t- Specify ordererOpt method: $TARGETORDERERS\n"
          shift
          ;;

      --evttimeout)
          shift
          EVTTIMEOUT=$1
          echo -e "\t- Specify event timeout: $EVTTIMEOUT\n"
          shift
          ;;

      --reqtimeout)
          shift
          REQTIMEOUT=$1
          echo -e "\t- Specify request timeout: $REQTIMEOUT\n"
          shift
          ;;

      --grpctimeout)
          shift
          GRPCTIMEOUT=$1
          echo -e "\t- Specify GRPC timeout: $GRPCTIMEOUT\n"
          shift
          ;;

      *)
          echo "Unrecognized command line argument: $1"
          usage
          ;;
    esac
done

    # setup CHANNEL
if [ $NCHAN -gt 0 ]; then
    for (( i=0; i < $NCHAN; i++ ))
    do
        j=$((i + 1))
        CHANNEL[$i]=$CHANPREFIX$j
    done
fi

    # setup ORGS
if [ $NORG -gt 0 ]; then
    for (( i=0; i < $NORG; i++ ))
    do
        j=$((i + 1))
        ORGS[$i]=$ORGPREFIX$j
    done
fi

printVars

    # sanity check: SCDIR
if [ "$SCDIR" == "" ]; then
    echo "SCDIR is required. Use option -d to specify."
    exit
elif [ ! -e $PTEDIR/$SCDIR ]; then
    echo "SCDIR does not exist: $PTEDIR/$SCDIR"
    exit
fi

    # create runDir
if [ -e $runDir ]; then
    rm -rf $runDir
fi
mkdir $runDir

echo "current dir: $CWD"


    # create/join channel
if [ $ChanProc == "YES" ]; then
    echo "create/join channel"
    ChannelProc
    cd $CWD
    echo "after create/join channel current dir: $CWD"
fi

if [ $RUNDUR -gt 0 ]; then
    NREQ=0
fi

    # install/instantiate chaincode
if [ $CCProc == "YES" ]; then
    echo "install/instantiate chaincode"
    ChaincodeProc
    cd $CWD
    echo "after install/instantiate chaincode current dir: $CWD"
fi

    # process transactions: prime
if [ $PrimeProc == "YES" ]; then
    echo "process transactions: prime"
    TransactionProc "QUERY"
    cd $CWD
    echo "after Prime Proc current dir: $CWD"
fi

    # process transactions
if [ "$TXType" != "" ]; then
    echo "process transactions: $TXType"
    TransactionProc $TXType
    cd $CWD
    echo "after TX Proc current dir: $CWD"
fi


cd $CWD

exit
