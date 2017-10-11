# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
# -------------------------------------------------------------
# This makefile defines the following targets
#
#   - ca - Clones the fabric-ca repository.
#   - ca-build - Clones fabric-ca repository and builds fabric-ca docker images.
#   - ca-docker - Builds fabric-ca docker images.
#   - ci-smoke - Executes the smoke tests.
#   - ci-daily - Executes the daily tests.
#   - fabric - Clone fabric repository.
#   - fabric-build - Execute fabric, fabric-docker targets and run behave-deps make target.
#   - fabric-ca - Builds the fabric-ca binaries.(Optional: Make fabric-ca if python prerequisites are not installed by default)
#   - fabric-docker - Builds fabric docker images.
# -------------------------------------------------------------

FABRIC = https://gerrit.hyperledger.org/r/fabric
FABRIC_CA = https://gerrit.hyperledger.org/r/fabric-ca
HYPERLEDGER_DIR = $(GOPATH)/src/github.com/hyperledger
INSTALL_BEHAVE_DEPS = $(GOPATH)/src/github.com/hyperledger/fabric-test/feature/scripts/install_behave.sh
.PHONY: 
fabric-ca: 
	cd feature/scripts
	@bash install_behave.sh

.PHONY: ci-smoke
ci-smoke: git-update fabric-build ca-build fabric-smoke-tests

.PHONY: git-update
git-update:
	@git submodule update --init --recursive


.PHONY: ci-daily
ci-daily: git-update fabric-build ca-build fabric-daily-tests

.PHONY: git-update
git-update:
	@git submodule update --init --recursive
.PHONY: fabric-build
fabric-build: fabric fabric-docker
	@make behave-deps -C $(HYPERLEDGER_DIR)/fabric

.PHONY: fabric
fabric:
	@git clone $(FABRIC) $(HYPERLEDGER_DIR)/fabric

.PHONY: fabric-docker
fabric-docker:
	@make docker -C $(HYPERLEDGER_DIR)/fabric
	@make behave-deps -C $(HYPERLEDGER_DIR)/fabric

.PHONY: ca-build
ca-build: ca ca-docker

.PHONY: ca
ca:
	@git clone $(FABRIC_CA) $(HYPERLEDGER_DIR)/fabric-ca

.PHONY: ca-docker
ca-docker:
	@make docker -C $(HYPERLEDGER_DIR)/fabric-ca

.PHONY: fabric-smoke-tests
fabric-smoke-tests:
	git submodule update --init --recursive
	cd regression/smoke && ./runSmokeTestSuite.sh

.PHONY: fabric-daily-tests
fabric-daily-tests:
	git submodule update --init --recursive
	cd regression/daily && ./runDailyTestSuite.sh
