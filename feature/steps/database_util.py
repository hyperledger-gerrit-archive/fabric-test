#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

import os
import json


def generateIndex(indexName, docName, fieldStr, path):
    fields = fieldStr.split(",")
    fieldData = []
    for field in fields:
        if ":" in field:
            keyfield = field.split(":")
            fieldData.append({"data.{}".format(keyfield[0]): keyfield[1]})
        else:
            fieldData.append("data.{}".format(field))

    generated = {"index": {"fields":fieldData},
                 "ddoc": docName,
                 "name": indexName,
                 "type": "json"}

    indexLoc = "/opt/gopath/src/{0}/META-INF/statedb/couchdb/indexes/".format(path)
    if not os.path.exists(indexLoc):
        os.makedirs(indexLoc)

    with open("{0}/{1}.json".format(indexLoc, indexName), "w") as fd:
        json.dump(generated, fd)
    print(os.listdir(indexLoc))
