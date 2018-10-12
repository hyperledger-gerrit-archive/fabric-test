#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

#
# runPTE.sh
# purpose:
#   1. npm install
#   2. convert the connection profile to PTE service credential json
#   3. install and instantiate chaincode
#   4. execute testcases using PTE

# FUNCTION: usage
#           Displays usage command line options; examples; exits.
usage () {
    echo -e "\nUSAGE:\t./runPTE.sh [options] [values]"
    echo
    echo -e "-h, --help\tView this help message"
    echo

    echo -e "--npm \t\tnpm install fabric-client packages"
    echo -e "\t\t(Default: none)"
    echo

    echo -e "--dir \trelative path from current directory to the directory that contains connection profiles to be converted"
    echo -e "\t\t(Required. Default: connectionprofile)"
    echo

    echo -e "-t, --testcase\tlist of testcases"
    echo

    echo -e "-s, --sanity\texecute a sanity test of 2 predefined testcases"
    echo -e "\t\t(testcases: FAB-3808-2i FAB-3811-2q)"
    echo

    echo -e "-a, --all\texecute all testcases"
    echo -e "\t\t(testcases listed above)"
    echo

    echo -e "\t\tAvailable testcases: FAB-3808-2i FAB-3811-2q FAB-3807-4i FAB-3835-4q FAB-4038-2i FAB-4036-2q FAB-7329-4i FAB-7333-4i"
    echo -e "For more detaila, refer to jira or ../PTE/CITest/."
    echo

    echo -e "Examples:"
    echo -e "./runPTE.sh --npm --dir connectionprofile -t FAB-3808-2i"
    echo -e "./runPTE.sh --dir connectionprofile -t FAB-3808-2i FAB-3811-2q"
    echo -e "./runPTE.sh -s"
    echo -e "./runPTE.sh -a"
    echo

    echo -e "Note:"
    echo -e "The tool installs/instantiates chaincode every time, so you may ignore these errors if the chaincode is already installed/instantiated:"
    echo -e "    error: [client-utils.js]: sendPeersProposal - Promise is rejected: Error: 2 UNKNOWN: chaincode error (status: 500, message: Error installing chaincode code ... chaincodes/sample_cc_ch1.v0 exists))"
    echo -e "    error: [client-utils.js]: sendPeersProposal - Promise is rejected: Error: 2 UNKNOWN: chaincode error (status: 500, message: chaincode exists sample_cc_ch1)"

}


# current working dir
CWD=$PWD
echo "CWD: $CWD"
# PTE dir
PTEDir=$CWD/../PTE
echo "PTEDir: $PTEDir"
# Logs dir
LOGSDir=$CWD/Logs
echo "LOGSDir: $LOGSDir"
if [ ! -e $LOGSDir ]; then
    mkdir -p $LOGSDir
fi

tCurr=`date +%Y%m%d%H%M%S`
testPTEReport=$LOGSDir"/pteReport-"$tCurr".log"
if [ -e $testPTEReport ]; then
    rm -rf $testPTEReport
fi

# default
ConnProfDir=$CWD"/connectionprofile"
NPMInstall="none"
TestCases="FAB-3808-2i"
Chaincodes=""
CProfConv="yes"
CCProc="yes"
CHANNEL="defaultchannel"


### install npm packages: fabric-client and fabric-ca-client
npmProc() {

    echo
    echo -e "          *****************************************************************************"
    echo -e "          *                              NPM installation                             *"
    echo -e "          *****************************************************************************"
    echo

    cd $PTEDir
    rm -rf node_modules
    npm install

    npm list | grep fabric
}



### generate connection profile and convert to PTE SC file
cProfConversion() {

    echo
    echo -e "          *****************************************************************************"
    echo -e "          *                       connection profile conversion                       *"
    echo -e "          *****************************************************************************"
    echo

    # convert to PTE service credential json
    cd $PTEDir/cprof-convert
    node convert.js $ConnProfDir

    cd $PTEDir
    rm -rf CITest/CISCFiles/*.json
    cp cprof-convert/pte-config.json CITest/CISCFiles/config-chan1-TLS.json
}


# pre-process
# $1: test case, e.g., FAB-3807-4i
# $2: chaincode, e.g., samplecc
testPreProc() {
    tcase=$1
    tcc=$2
    echo -e "[testPreProc] executes test pre-process: testcase $tcase, chaincode $tcc"
    cd $PTEDir
    sed -i 's/testorgschannel1/defaultchannel/g' CITest/$tcase/preconfig/channels/*
    sed -i 's/testorgschannel1/defaultchannel/g' CITest/$tcase/preconfig/$tcc/*
    sed -i 's/testorgschannel1/defaultchannel/g' CITest/$tcase/$tcc/*
    sed -i 's/testorgschannel1/defaultchannel/g' CITest/$tcase/preconfig/$tcc/*
    sed -i 's/testorgschannel1/defaultchannel/g' CITest/$tcase/$tcc/*

}

# priming
# $1: chaincode, e.g., samplejs
primeProc() {

    cc=$1
    pcase="FAB-query-TLS"
    echo
    echo -e "          *****************************************************************************"
    echo -e "          *                  executing priming: $pcase/$cc                            *"
    echo -e "          *****************************************************************************"
    echo

    sed -i 's/testorgschannel1/defaultchannel/g' CITest/$pcase/$cc/*
    sed -i 's/testorgschannel2/defaultchannel/g' CITest/$pcase/$cc/*
    tCurr=`date +%Y%m%d%H%M%S`
    testLogs=$LOGSDir/$pcase"-"$tCurr".log"
    ./pte_driver.sh CITest/$pcase/$cc"/runCases-FAB-query-q1-TLS.txt" >& $testLogs
}

# install/instantiate chaincode
# $1: test case, e.g., FAB-3807-4i
# $2: chaincode, e.g., samplecc
ccProc() {
    tcase=$1
    chaincode=$2
    echo -e "[ccProc] executes test chaincode process: $tcase $chaincode"

    if [[ "${Chaincodes[@]}" =~ "$chaincode" ]]; then
       echo -e "[ccProc] $chaincode was installed/instantiated"
       return
    fi

    j=${#Chaincodes[@]}
    j=$[ j + 1 ]
    Chaincodes[$j]=$chaincode

    cd $PTEDir
    # install chaincode
    installTXT=CITest/$tcase/preconfig/$chaincode/runCases-$chaincode"-install-TLS.txt"
    echo -e "[ccProc] ./pte_driver.sh $installTXT"
    ./pte_driver.sh $installTXT

    # instantiate chaincode
    echo -e "[ccProc] instantiate chaincode: $chaincode"
    instantiateTXT=CITest/$tcase/preconfig/$chaincode/runCases-$chaincode"-instantiate-TLS.txt"
    echo -e "[ccProc] ./pte_driver.sh $instantiateTXT"
    ./pte_driver.sh $instantiateTXT

    # priming ...
    primeProc $chaincode
}

# get chaincode from the testcase
# $1: test case, e.g., FAB-3807-4i
getCCfromTestcase() {
    tc=$1
    #echo -e "getCC: testcase=$testcase"
    cd $PTEDir/CITest

    # search for chaincode for each testcase
    ccDir=`ls $tc`
    for dd in ${ccDir[@]}; do
        if [ $dd == "samplecc" ] || [ $dd == "samplejs" ] || [ $dd == "marbles02" ]; then
            res=$dd
        fi
    done

}

#execute testcases
testProc(){
    pteReport=$PTEDir/pteReport.txt

    for testcase in "${TestCases[@]}"; do
        local res="none"
        getCCfromTestcase $testcase

        cd $PTEDir

        # install/instantiate chaincode
        if [ $CCProc != "none" ] && [ $res != "none" ]; then
            ccProc $testcase $res
        fi

        testPreProc $testcase $res

        if [ -e $pteReport ]; then
            rm -rf $pteReport
        fi

        echo
        echo -e "          *****************************************************************************"
        echo -e "          *                  executing testcase: $testcase                            *"
        echo -e "          *****************************************************************************"
        echo
        echo -e "testcase: $testcase, chaincode: $res" >> $pteReport
        tCurr=`date +%Y%m%d%H%M%S`
        testLogs=$LOGSDir/$testcase"-"$tCurr".log"
        ###./pte_driver.sh CITest/$testcase/$res/run-$testcase"-TLS.txt"
        ./pte_mgr.sh CITest/$testcase/$res/PTEMgr-$testcase"-TLS.txt" >& $testLogs

        # save pteReport
        cat $pteReport >> $testPTEReport
    done

}


# GET CUSTOM OPTIONS
tCurr=`date +%Y%m%d%H%M%S`
echo -e "[$0] starts at $tCurr"
while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in

      -h | --help)
          usage        # displays usage info; exits
          exit 0
          ;;

      --npm)
          NPMInstall="yes"     # npm installation
          echo -e "\t- Specify NPMInstall: $NPMInstall\n"
          shift
          ;;

      --dir)
          shift
          CProfConv="yes"     # connection profile conversion
          ConnProfDir=$CWD/$1
          echo -e "\t- Specify ConnProfDir: $ConnProfDir\n"
          shift
          ;;

      -s | --sanity)
          NPMInstall="yes"     # npm installation
          CCProc="yes"         # install/instantiate chaincode
          TestCases=("FAB-3808-2i" "FAB-3811-2q")  # testcases
          echo -e "\t- Specify CProfConv: $CProfConv\n"
          shift
          ;;

      -a | --all)
          NPMInstall="yes"     # npm installation
          CCProc="yes"         # install/instantiate chaincode
          TestCases=("FAB-3808-2i" "FAB-3811-2q" "FAB-3807-4i" "FAB-3835-4q" "FAB-4038-2i" "FAB-4036-2q" "FAB-7329-4i" "FAB-7333-4i")  # testcases
          echo -e "\t- Specify CProfConv: $CProfConv\n"
          shift
          ;;

      -t | --testcase)
          shift
          i=0
          TestCases[$i]=$1  # testcases
          shift
          until [[ $(eval "echo \$1") =~ ^-.* ]] || [ -z $(eval "echo \$1") ]; do
              i=$[ i + 1]
              TestCases[$i]=$1
              shift
          done
          echo -e "\t- Specify TestCases: ${TestCases[@]}"
          ;;

      *)
          echo "Unrecognized command line argument: $1"
          usage
          exit 1
          ;;
    esac
done


echo
echo -e "test setup"
echo -e "npm installation: $NPMInstall"
echo -e "TestCases: ${TestCases[@]}"
echo -e "chaincode installation/instantiation: $CCProc"

#sanity check ConnProfDir
if [ ! $ConnProfDir ]; then
    echo "[$0] Error: connection profile is required."
    usage
    exit 1
elif [ ! -e $ConnProfDir ]; then
    echo -e "[$0] Error: $ConnProfDir does not exist"
    usage
    exit 1
else
    jsonCnt=`ls $ConnProfDir/*.json | wc -l`
    if [ $jsonCnt == 0 ]; then
        echo -e "[$0] Error: no connection profile found in $ConnProfDir"
        usage
        exit 1
    fi
fi
echo -e "connection profile dir: $ConnProfDir"

# npm install fabric packages
if [ $NPMInstall != "none" ]; then
    npmProc
fi

# connection profile conversion
if [ $CProfConv != "none" ]; then
    cProfConversion
fi


# execute PTE transactions
if [ ${#TestCases[@]} -gt 0 ]; then

    testProc

    echo
    echo -e "          *****************************************************************************"
    echo -e "          *                              TEST COMPLETED                               *"
    echo -e "          *****************************************************************************"
    echo
    echo
    echo -e "          *****************************************************************************"
    echo -e "          test logs dir: $LOGSDir"
    echo -e "          test results: $testPTEReport"
    echo -e "          *****************************************************************************"
    echo

fi


tCurr=`date +%Y%m%d%H%M%S`
echo -e "[$0] ends at $tCurr"
exit 0
