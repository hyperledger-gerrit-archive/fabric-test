#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

mkdir ./output > /dev/null 2>&1

function showHelp {
  echo "Usage: "
  echo "  convert.sh [flags]"
  echo ""
  echo "Flags: "
  echo "  -h|--help    Show help (print this message)"
}

if [[ $# -gt 1 ]] ; then
  showHelp
  exit 1
fi

OP=$1
DIR=""
shift
case $OP in
  -h|--help )
    showHelp
    exit 0
    ;;
  * )
    echo "Unknown command: $OP"
    showHelp
    exit 1
    ;;
esac

node scripts/convert.js
echo "Converted connection profiles to PTE format in ./output/pte-config.json"
