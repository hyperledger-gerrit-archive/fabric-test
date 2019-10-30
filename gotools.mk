# Copyright the Hyperledger Fabric contributors. All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

GOTOOLS = gocov gocov-xml goimports golint ginkgo
TOOLS = build/tools

.PHONY: gotools
gotools: $(patsubst %,build/tools/%, $(GOTOOLS))

build/tools/%: tools/gotools/go.mod tools/gotools/tools.go
	@mkdir -p $(@D)
	@$(eval TOOL = ${subst build/tools/,,${@}})
	@$(eval FQP = $(shell grep ${TOOL} tools/gotools/tools.go | cut -d " " -f2 | grep ${TOOL}\"$))
	@echo Installing ${TOOL} at ${CURDIR}/$(TOOLS) from ${FQP}
	@cd tools/gotools && GO111MODULE=on GOBIN=${CURDIR}/$(TOOLS) go install ${FQP}
