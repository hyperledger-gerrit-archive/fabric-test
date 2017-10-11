# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
# -------------------------------------------------------------
# This makefile defines the following targets
#
#   - ca - clones the fabric-ca repository.
#   - ci-smoke - executes the smoke tests.
#   - ci-daily - executes the daily tests.
#   - docker-images - builds fabric & ca docker images.
#   - fabric - clone fabric repository.
#   - fabric-smoke-tests - runs Smoke Test Suite
#   - fabric-daily-tests - runs Daily Test Suite
#   - git-update - updates git submodules
#
# -------------------------------------------------------------

FABRIC = https://gerrit.hyperledger.org/r/fabric
FABRIC_CA = https://gerrit.hyperledger.org/r/fabric-ca
HYPERLEDGER_DIR = $(GOPATH)/src/github.com/hyperledger
INSTALL_BEHAVE_DEPS = $(GOPATH)/src/github.com/hyperledger/fabric-test/feature/scripts/install_behave.sh
FABRIC_DIR = fabric
CA_DIR = fabric-ca

.PHONY: ci-smoke
ci-smoke: git-update fabric ca docker-images fabric-smoke-tests

.PHONY: git-update
git-update:
	@git submodule update --init --recursive

.PHONY: behave-deps
behave-deps:
	@bash $(INSTALL_BEHAVE_DEPS)

.PHONY: ci-daily
ci-daily: git-update fabric ca docker-images fabric-daily-tests

.PHONY: fabric
fabric:
	if [ ! -d "$(HYPERLEDGER_DIR)/$(FABRIC_DIR)" ]; then \
		echo "Clone FABRIC REPO"; \
		cd $(HYPERLEDGER_DIR); \
		git clone $(FABRIC) $(HYPERLEDGER_DIR)/$(FABRIC_DIR); \
	fi
	cd $(HYPERLEDGER_DIR)/$(FABRIC_DIR) && git pull $(FABRIC)

.PHONY: docker-images
docker-images:
	@make docker -C $(HYPERLEDGER_DIR)/fabric
	@make native -C $(HYPERLEDGER_DIR)/fabric
	@make docker -C $(HYPERLEDGER_DIR)/fabric-ca

.PHONY: ca
ca:
	if [ ! -d "$(HYPERLEDGER_DIR)/$(CA_DIR)" ]; then \
		echo "Clone FABRIC_CA REPO"; \
		cd $(HYPERLEDGER_DIR); \
		git clone $(FABRIC_CA) $(HYPERLEDGER_DIR)/$(CA_DIR); \
	fi
	cd $(HYPERLEDGER_DIR)/$(CA_DIR) && git pull $(FABRIC_CA)

.PHONY: fabric-smoke-tests
fabric-smoke-tests:
	cd regression/smoke && ./runSmokeTestSuite.sh

.PHONY: fabric-daily-tests
fabric-daily-tests:
	cd regression/daily && ./runDailyTestSuite.sh
