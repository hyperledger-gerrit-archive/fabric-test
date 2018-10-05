#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# run full suite testcases on a cloud
usage() {
    echo -e "\nUSAGE:\t./sanity.js [options] [values]"
    echo
    echo -e "-h, --help\tView this help message"
    echo

    echo -e "--cloud \ttargeted cloud [IBM|AWS]"
    echo -e "\t\t(Default: IBM)"
    echo

    exit
}

cloud="IBM"

while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in

      -h | --help)
          usage        # displays usage info; exits
          ;;

      --cloud)
          shift
          cloud=$1     # could type
          echo -e "\t- Specify cloud: $cloud\n"
          if [ $cloud != "IBM" ]; then
             echo -e "[$0] unsupported cloud type [$cloud]"
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


# run full test suite on IBM cloud
./runCloudPTE.sh --cloud $cloud -a
