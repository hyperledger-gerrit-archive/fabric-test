# Copyright the Hyperledger Fabric contributors. All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

GOTOOLS = gocov gocov-xml goimports golint ginkgo

.PHONY: gotools
gotools: $(patsubst %,build/tools/%, $(GOTOOLS))

build/tools/%: tools/go.mod tools/tools.go
	@mkdir -p $(@D)
	@$(eval TOOL = ${subst build/tools/,,${@}})
	@$(eval FQP = $(shell grep ${TOOL} tools/tools.go | cut -d " " -f2 | grep ${TOOL}\"$))
	@echo Installing ${TOOL} at ${CURDIR}/build/tools$(TOOLS) from ${FQP}
	@cd tools && GO111MODULE=on GOBIN=${CURDIR}/build/tools/$(TOOLS) go install ${FQP}
