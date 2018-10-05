#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# run full suite testcases on a cloud
usage() {
    echo -e "\nUSAGE:\t./fullSuite.js [options] [values]"
    echo
    echo -e "-h, --help\tView this help message"
    echo

    echo -e "--cprof \tabsolute path of the directory that contains connection profiles to be converted"
    echo -e "\t\t(Default: none)"
    echo

    echo -e "Example:"
    echo -e "./fullSuite.sh --cprof /home/ibmadmin/gopath/src/github.com/hyperledger/fabric-test/testSuites/cloud/IBM/creds/connectionprofiles"
    exit
}

ConnProfDir=""

while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in

      -h | --help)
          usage        # displays usage info; exits
          ;;

      --cprof)
          shift
          ConnProfDir=$1
          echo -e "\t- Specify ConnProfDir: $ConnProfDir\n"
          if [ ! -e $ConnProfDir ]; then
             echo -e "[$0] Error: $ConnProfDir does not exist"
             exit
          fi
          shift
          ;;

      *)
          echo "Unrecognized command line argument: $1"
          usage
          ;;
    esac
done

if [ ! $ConnProfDir ]; then
    echo "[$0] Error: connection profile is required."
    usage
fi

# run full test suite
./runCloudPTE.sh --cprof $ConnProfDir -a
