#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

SMOKEDIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/smoke"


cd ../daily

echo "========== Ledger component performance tests..."
py.test -v --junitxml results_ledger_lte.xml ledger_lte.py::perf_goleveldb::test_FAB_3790_VaryNumParallelTxPerChain


py.test -v --junitxml results_ledger_lte.xml ledger_lte.py::perf_couchdb::test_FAB_3870_VaryNumParallelTxPerChain
