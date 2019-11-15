#!/bin/bash

for dir in $PWD/../chaincodes/*/*/
do
    if [[ "$dir" == */go/ ]]; then
        cd $dir
        go mod tidy
        cd -
    fi
done
