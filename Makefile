#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
# -------------------------------------------------------------
# This makefile defines the following targets
#
#   - all (default) - builds all targets and runs all tests.
#   - ci-smoke: Executes the smoke test. 
#   - fabric-ca - builds the fabric-ca binaries.
#   - pip-install - Installs the dependencies required.

all: ci-smoke fabric-ca pip-install
FABRIC = https://gerrit.hyperledger.org/r/fabric
FABRIC_CA = https://gerrit.hyperledger.org/r/fabric-ca
FABRIC_WORKING_DIR = $GOPATH/src/github.com/hyperledger
#CA_WORKING_DIR = ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test/fabric-ca
PIP_CONFIG_PATH = $GOPATH/src/github.com/hyperledger/fabric-test/feature/scripts/install_behave.sh
PIP_PATH = $GOPATH/src/github.com/hyperledger/fabric-test/feature/scripts
DAILY_CONFIG_PATH = $GOPATH/src/github.com/hyperledger/fabric-test/feature/scripts/install_behavedaily.sh



ci-smoke: fabric-build ca-build pip-install

.PHONY: fabric-build
fabric-build: fabric fabric-docker
	@make behave-deps -C $(FABRIC_WORKING_DIR)/fabric

.PHONY: fabric
fabric:
	@git clone $(FABRIC) $(FABRIC_WORKING_DIR)/fabric
	
.PHONY: fabric-docker
fabric-docker: 
	@make docker -C $(FABRIC_WORKING_DIR)/fabric
	
ca-build: ca ca-docker

.PHONY: ca
ca:
	@git clone $(FABRIC_CA) $(FABRIC_WORKING_DIR)/fabric-ca

.PHONY: ca-docker
ca-docker:
	@make docker -C $(FABRIC_WORKING_DIR)/fabric-ca

.PHONY: fabric-tests
fabric-tests:
	@bash $(PIP_CONFIG_PATH)

daily-test: ed ex

.PHONY: ed
ed:
	@cat $(PIP_CONFIG_PATH) | sed 's/smoke/daily/g' $(PIP_CONFIG_PATH) > $(PIP_PATH)/install_behavedaily.sh
	@chmod 777 $(DAILY_CONFIG_PATH)

.PHONY: ex
ex:
	@bash $(DAILY_CONFIG_PATH)
