# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
# -------------------------------------------------------------
# This makefile defines the following targets
#
#   - ci-smoke: Executes the smoke tests.
#   - fabric-ca - builds the fabric-ca binaries.
#   - fabric-docker - builds fabric docker images
#   - fabric - clone fabric repository
#   - ca  - clone fabric-ca repository
#   - ca-docker - Builds fabric-ca docker images
#   - fabric-tests - Install pip modules and executes tests
#   - fabric-build - Execute fabric, fabric-docker targets and run behave-deps make target

FABRIC = https://gerrit.hyperledger.org/r/fabric
FABRIC_CA = https://gerrit.hyperledger.org/r/fabric-ca
FABRIC_DIR = $(GOPATH)/src/github.com/hyperledger
PIP_PATH = $(GOPATH)/src/github.com/hyperledger/fabric-test/feature/scripts/install_behave.sh

.PHONY: ci-smoke
ci-smoke: fabric-build ca-build fabric-smoke-tests

.PHONY: ci-daily
ci-daily: fabric-build ca-build fabric-daily-tests

.PHONY: fabric-build
fabric-build: fabric fabric-docker
	@make behave-deps -C $(FABRIC_DIR)/fabric

.PHONY: fabric
fabric:
	@git clone $(FABRIC) $(FABRIC_DIR)/fabric

.PHONY: fabric-docker
fabric-docker:
	@make docker -C $(FABRIC_DIR)/fabric
	@make behave-deps -C $(FABRIC_DIR)/fabric

.PHONY: ca-build
ca-build: ca ca-docker

.PHONY: ca
ca:
	@git clone $(FABRIC_CA) $(FABRIC_DIR)/fabric-ca

.PHONY: ca-docker
ca-docker:
	@make docker -C $(FABRIC_DIR)/fabric-ca

.PHONY: fabric-smoke-tests
fabric-smoke-tests:
	git submodule update --init --recursive
	cd regression/smoke && ./runSmokeTestSuite.sh

.PHONY: fabric-daily-tests
fabric-daily-tests:
	git submodule update --init --recursive
	cd regression/daily && ./runDailyTestSuite.sh
