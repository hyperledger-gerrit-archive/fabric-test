#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


# run short test suite on a cloud

usage() {
    echo -e "\nUSAGE:\t./sanity.js [options] [values]"
    echo
    echo -e "-h, --help\tView this help message"
    echo

    echo -e "--cprof \trelative path from current directory to the directory that contains connection profiles to be converted"
    echo -e "\t\t(Default: none)"
    echo

    echo -e "Example:"
    echo -e "./sanity.sh --cprof IBM/creds/connectionprofiles"

}


while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in

      -h | --help)
          usage        # displays usage info; exits
          exit 0
          ;;

      --cprof)
          shift
          ConnProfDir=$1     # could type
          echo -e "\t- Specify ConnProfDir: $ConnProfDir\n"
          shift
          ;;

      *)
          echo "Unrecognized command line argument: $1"
          usage
          exit 1
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
./runCloudPTE.sh --cprof $ConnProfDir --npm -t FAB-3808-2i FAB-3811-2q
