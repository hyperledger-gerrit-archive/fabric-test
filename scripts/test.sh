#!/bin/bash -e
set -o pipefail


cd ../chaincodes/marbles02/go
go mod tidy
cd -
