#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

import os
import sys
import time
import subprocess
import shutil
import json
import config_util


def generateIndex(indexName, docName, field, path):
    generated = {"index": {"fields":["data.{}".format(field)]},
                 "ddoc": docName,
                 "name": indexName,
                 "type": "json"}

    indexLoc = "/opt/gopath/src/{0}/META-INF/statedb/couchdb/indexes/".format(path)
    if not os.path.exists(indexLoc):
        os.makedirs(indexLoc)

    with open("{0}/{1}.json".format(indexLoc, indexName), "w") as fd:
        json.dump(generated, fd)
    print(os.listdir(indexLoc))
