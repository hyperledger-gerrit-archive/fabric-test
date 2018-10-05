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

    echo -e "--cprof \trelative path from current directory to the directory that contains connection profiles to be converted"
    echo -e "\t\t(Default: none)"
    echo

    echo -e "Example:"
    echo -e "./fullSuite.sh --cprof IBM/creds/connectionprofiles"
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
          shift
          ;;

      *)
          echo "Unrecognized command line argument: $1"
          usage
          ;;
    esac
done

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
        echo -e "[$0] Error: no connection profile contained in $ConnProfDir"
        usage
        exit 1
    fi
fi

# run full test suite
./runCloudPTE.sh --cprof $ConnProfDir -a
