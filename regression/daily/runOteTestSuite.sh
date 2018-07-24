#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
echo "======== Orderer Performance tests...========"
py.test -v --junitxml results_orderer_ote.xml orderer_ote.py
