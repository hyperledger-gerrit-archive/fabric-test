#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test

git submodule update --init --recursive

# Create virtual Environment to test behave tests

virtualenv -p /usr/bin/python2.7 venv
export PS1="test"
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python2.7
source venv/bin/activate
# Install all required python modules
pip install ecdsa
pip install behave
pip install grpcio-tools
pip install "pysha3==1.0b1"
pip install b3j0f.aop
pip install jinja2
pip install "pyopenssl==17.2.0"
pip install ecdsa
pip install python-slugify
pip install pyyaml
pip install pykafka
pip install requests
pip install pyexecjs
pip install cython
pip install pyjnius

echo "==========> Behave feature and system tests..."
cd feature
behave --junit --junit-directory ../regression/daily/. --tags=-skip --tags=smoke
cd -

deactivate
