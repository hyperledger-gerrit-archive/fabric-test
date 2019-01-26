#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# test_preconfig.sh
# preconfig a Blockchain network: create/join channels and install/instantiate chaincode

# reuqirement: a service credential json file stored in directory PTE/PTEScaleTest-SC

# default vars
myCC="samplecc"
myNCHAN=1
myNORG=1

CWD=$PWD

usage () {
    echo -e "\nUsage:\t./test_preconfig.sh [option]"
    echo
    echo -e "\t-h, --help\tView this help message"
    echo
    echo -e "\t--chaincode\tchaincode [samplecc|samplejs|marblecc]"
    echo -e "\t\tDefault: samplecc"
    echo
    echo -e "\t--nchan\tnumber of channels [integer]"
    echo -e "\t\tDefault: 1."
    echo
    echo -e "\t--norg\tnumber of org [integer]"
    echo -e "\t\tDefault: 1."
    echo
    echo -e "\tExamples:"
    echo -e "\t    ./test_preconfig.sh -a samplecc --nchan 100 --norg 3"

}

#input parameters
while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in

      -h | --help)
          usage                    # displays usage info
          exit 0                   # exit cleanly, since the use just asked for help/usage info
          ;;

      --chaincode)
          shift
          myCC=$1                   # chaincode
          shift
          ;;

      --nchan)
          shift
          myNCHAN=$1                 # number of channels
          shift
          ;;

      --norg)
          shift
          myNORG=$1                  # number of org
          shift
          ;;

      *)
          echo "Error: Unrecognized command line argument: $1"
          usage
          exit 1
          ;;

    esac
done

cd $CWD
cd ../scenarios
set -x
./runScaleTraffic.sh  -a $myCC --preconfig --nchan $myNCHAN --norg $myNORG
set +x

exit 0
