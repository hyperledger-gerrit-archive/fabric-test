# Hyperledger Fabric PTE Connection Profile Conversion Tool

This is a command-line tool for converting [Hyperledger Fabric](https://www.hyperledger.org/projects/fabric) blockchain networks' connection profiles to a JSON file in a format compatible with Fabric's [Performance Traffic Engine (PTE)](https://github.com/hyperledger/fabric-test/tree/master/tools/PTE).

## Prerequisites

* Ensure you have [Go](https://golang.org/) and [Node.js](https://nodejs.org/en/) installed on your machine.
* Clone the `fabric-test` repository into `$GOPATH/src/github.com/hyperledger/`.

## Setup

1. Run `cd $GOPATH/src/github.com/hyperledger/fabric-test/tools/PTE/cprof-convert/`.
2. If it doesn't already exist, create a directory called `config/` inside `cprof-convert/`.
3. Place your network's connection profile(s) in `config/`. These should be JSON files renamed to start with a prefix of `creds` (such as `creds0.json`).

## Usage and Details

The script to run to use the tool is `./convert.sh` (make sure your working directory is `cprof-convert/` when you run this command).
You can also run `node scripts/convert.js` for now, but a shell script wrapper has been written so that it is easier to add configuration options and other extensions in the future.

This tool takes in a single network's connection profile(s) (it is possible that one network may have multiple connection profiles) and converts them to a single PTE configuration file for that network.
It generates a directory named `output/` inside `cprof-convert/` and creates a single file named `pte-config.json` inside `output/`.
This file contains the generated PTE configuration based on the information extracted from the aforementioned connection profile(s) in `config/` (see above).
It is important to note that the tool expects that _all_ of the connection profiles inside `config/` are for a single network.
