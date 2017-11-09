#!/bin/bash
echo "#########################################"
echo "#                                       #"
echo "#            WELCOME TO OTE             #"
echo "#                                       #"
echo "#########################################"

go build
go test -run $TESTCASE -timeout=90m
mkdir logs
mv *.log logs/$TESTCASE.log
