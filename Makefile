# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
# -------------------------------------------------------------
# This makefile defines the following targets
#
#   - ci-smoke - update submodules, build docker images
#                and executes smoke tests.
#   - ci-daily - update submodules, build docker images
#                and executes daily test suite.
#   - docker-images - builds fabric & ca docker images.
#   - smoke-tests - runs Smoke Test Suite
#   - daily-tests - runs Daily Test Suite
#   - git-update - updates git submodules
#   - pre_setup  - installs node and behave pre-requisites
#   - clean  -   cleans the docker containers and images
#
# ------------------------------------------------------------------

FABRIC = https://gerrit.hyperledger.org/r/fabric
FABRIC_CA = https://gerrit.hyperledger.org/r/fabric-ca
HYPERLEDGER_DIR = $(GOPATH)/src/github.com/hyperledger
INSTALL_BEHAVE_DEPS = $(GOPATH)/src/github.com/hyperledger/fabric-test/feature/scripts/install_behave.sh
FABRIC_DIR = $(HYPERLEDGER_DIR)/fabric
CA_DIR = $(HYPERLEDGER_DIR)/fabric-ca
DOCKER_ORG = hyperledger
PRE_SETUP = $(GOPATH)/src/github.com/hyperledger/fabric-test/pre_setup.sh

.PHONY: ci-smoke
ci-smoke: git-update pre-setup docker-images smoke-tests clean

.PHONY: git-update
git-update:
	@git submodule update --init --recursive

.PHONY: pre-setup
pre-setup:
	@bash $(PRE_SETUP)
#	@bash $(INSTALL_BEHAVE_DEPS)

.PHONY: ci-daily
ci-daily: git-update pre-setup docker-images daily-tests clean

.PHONY: docker-images
docker-images:
	@make docker -C $(HYPERLEDGER_DIR)/fabric-test/fabric
	@make native -C $(HYPERLEDGER_DIR)/fabric-test/fabric
	@make docker -C $(HYPERLEDGER_DIR)/fabric-test/fabric-ca

.PHONY: smoke-tests
smoke-tests:
	cd $(HYPERLEDGER_DIR)/fabric-test/regression/smoke && ./runSmokeTestSuite.sh

.PHONY: daily-tests
daily-tests:
	cd $(HYPERLEDGER_DIR)/fabric-test/regression/daily && ./runDailyTestSuite.sh

.PHONY: clean
clean:
	-docker ps -aq | xargs -I '{}' docker rm -f '{}'
	-docker images -q $(DOCKER_ORG)/fabric-* | xargs -I '{}' docker rmi -f '{}'
