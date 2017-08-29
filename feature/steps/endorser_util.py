# Copyright IBM Corp. 2017 All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import os
import sys
import subprocess
import time
import common_util

try:
    pbFilePath = "../fabric/bddtests"
    sys.path.insert(0, pbFilePath)
    from peer import chaincode_pb2
except:
    print("ERROR! Unable to import the protobuf libraries from the ../fabric/bddtests directory: {0}".format(sys.exc_info()[0]))
    sys.exit(1)

# The default channel ID
SYS_CHANNEL_ID = "behavesyschan"
TEST_CHANNEL_ID = "behavesystest"


def get_chaincode_deploy_spec(projectDir, ccType, path, name, args):
    subprocess.call(["peer", "chaincode", "package",
                     "-n", name,
                     "-c", '{"Args":{0}}'.format(args),
                     "-p", path,
                     "configs/{0}/test.file".format(projectDir)], shell=True)
    ccDeploymentSpec = chaincode_pb2.ChaincodeDeploymentSpec()
    with open("test.file", 'rb') as f:
        ccDeploymentSpec.ParseFromString(f.read())
    return ccDeploymentSpec


def install_chaincode(context, chaincode, peers):
    configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
    output = {}
    for peer in peers:
        peerParts = peer.split('.')
        org = '.'.join(peerParts[1:])
        setup = ["/bin/bash", "-c",
                 '"CORE_PEER_MSPCONFIGPATH={0}/peerOrganizations/{1}/users/Admin@{1}/msp'.format(configDir, org),
                 'CORE_PEER_LOCALMSPID={0}'.format(org),
                 'CORE_PEER_ID={0}'.format(peer),
                 'CORE_PEER_ADDRESS={0}:7051'.format(peer)]
        command = ["peer", "chaincode", "install",
                   "--name", chaincode['name'],
                   "--version", str(chaincode.get('version', 0)),
                   "--path", chaincode['path']]
        if context.tls:
            setup.append('CORE_PEER_TLS_ROOTCERT_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/ca.crt'.format(configDir, org, peer))
            setup.append('CORE_PEER_TLS_CERT_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/server.crt'.format(configDir, org, peer))
            setup.append('CORE_PEER_TLS_KEY_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/server.key'.format(configDir, org, peer))
        if "orderers" in chaincode:
            command = command + ["--orderer", '{0}:7050'.format(chaincode["orderers"][0])]
        if "user" in chaincode:
            command = command + ["--username", chaincode["user"]]
        if "policy" in chaincode:
            command = command + ["--policy", chaincode["policy"]]
        command.append('"')
        ret = context.composition.docker_exec(setup + command, ['cli'])
        output[peer] = ret['cli']
    print("[{0}]: {1}".format(" ".join(setup + command), output))
    return output


def instantiate_chaincode(context, chaincode, containers):
    configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
    args = chaincode.get('args', '[]').replace('"', r'\"')
    setup = ["/bin/bash", "-c",
             '"CORE_PEER_MSPCONFIGPATH={0}/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp'.format(configDir),
             'CORE_PEER_LOCALMSPID=org1.example.com',
             'CORE_PEER_ID=peer0.org1.example.com',
             'CORE_PEER_ADDRESS=peer0.org1.example.com:7051']
    command = ["peer", "chaincode", "instantiate",
               "--name", chaincode['name'],
               "--version", str(chaincode.get('version', 0)),
               "--channelID", str(chaincode.get('channelID', TEST_CHANNEL_ID)),
               "--ctor", r"""'{\"Args\": %s}'""" % (args)]
    if context.tls:
        setup.append('CORE_PEER_TLS_ROOTCERT_FILE={0}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt'.format(configDir))
        setup.append('CORE_PEER_TLS_CERT_FILE={0}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt'.format(configDir))
        setup.append('CORE_PEER_TLS_KEY_FILE={0}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key'.format(configDir))
        command = command + ["--tls",
                             common_util.convertBoolean(context.tls),
                             "--cafile",
                             '{0}/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem'.format(configDir)]
    if "orderers" in chaincode:
        command = command + ["--orderer", '{0}:7050'.format(chaincode["orderers"][0])]
    if "user" in chaincode:
        command = command + ["--username", chaincode["user"]]
    if "policy" in chaincode:
        command = command + ["--policy", chaincode["policy"]]
    command.append('"')

    ret = context.composition.docker_exec(setup + command, ['peer0.org1.example.com'])
    print("[{0}]: {1}".format(" ".join(setup+command), ret))
    return ret


def create_channel(context, containers, orderers, channelId=TEST_CHANNEL_ID):
    configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
    ret = context.composition.docker_exec(["ls", configDir], containers)

    setup = ["/bin/bash", "-c",
             '"CORE_PEER_MSPCONFIGPATH={0}/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp'.format(configDir),
             'CORE_PEER_LOCALMSPID=org1.example.com',
             'CORE_PEER_ID=peer0.org1.example.com',
             'CORE_PEER_ADDRESS=peer0.org1.example.com:7051']
    command = ["peer", "channel", "create",
               "--file", "/var/hyperledger/configs/{0}/{1}.tx".format(context.composition.projectName, channelId),
               "--channelID", channelId,
               "--timeout", "120", # This sets the timeout for the channel creation instead of the default 5 seconds
               "--orderer", '{0}:7050'.format(orderers[0])]
    if context.tls:
        setup.append('CORE_PEER_TLS_ROOTCERT_FILE={0}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt'.format(configDir))
        setup.append('CORE_PEER_TLS_CERT_FILE={0}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt'.format(configDir))
        setup.append('CORE_PEER_TLS_KEY_FILE={0}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key'.format(configDir))
        command = command + ["--tls",
                             common_util.convertBoolean(context.tls),
                             "--cafile",
                             '{0}/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem'.format(configDir)]

    command.append('"')

    output = context.composition.docker_exec(setup+command, ['cli'])
    print("[{0}]: {1}".format(" ".join(setup+command), output))

    # For now, copy the channel block to the config directory
    output = context.composition.docker_exec(["cp",
                                              "{0}.block".format(channelId),
                                              configDir],
                                             ['cli'])
    print("[{0}]: {1}".format(" ".join(command), output))
    return output


def fetch_channel(context, peers, orderers, channelId=TEST_CHANNEL_ID):
    configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
    for peer in peers:
        peerParts = peer.split('.')
        org = '.'.join(peerParts[1:])
        setup = ["/bin/bash", "-c",
                   '"CORE_PEER_MSPCONFIGPATH={0}/peerOrganizations/{1}/users/Admin@{1}/msp'.format(configDir, org)]
        command = ["peer", "channel", "fetch", "config",
                   "/var/hyperledger/configs/{0}/{1}.block".format(context.composition.projectName, channelId),
                   "--file", "/var/hyperledger/configs/{0}/{1}.tx".format(context.composition.projectName, channelId),
                   "--channelID", channelId,
                   "--orderer", '{0}:7050'.format(orderers[0])]
        if context.tls:
            setup.append('CORE_PEER_TLS_ROOTCERT_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/ca.crt'.format(configDir, org, peer))
            setup.append('CORE_PEER_TLS_CERT_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/server.crt'.format(configDir, org, peer))
            setup.append('CORE_PEER_TLS_KEY_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/server.key'.format(configDir, org, peer))
            command = command + ["--tls",
                                 common_util.convertBoolean(context.tls),
                                 "--cafile",
                                 '{0}/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem'.format(configDir)]

        command.append('"')

        output = context.composition.docker_exec(setup+command, [peer])
        print("Fetch: {0}".format(str(output)))
#        assert "Error occurred" not in str(output[peer]), str(output[peer])
    print("[{0}]: {1}".format(" ".join(setup+command), output))
    return output


def join_channel(context, peers, orderers, channelId=TEST_CHANNEL_ID):
    configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)

    for peer in peers:
        peerParts = peer.split('.')
        org = '.'.join(peerParts[1:])
        setup = ["/bin/bash", "-c",
                 '"CORE_PEER_MSPCONFIGPATH={0}/peerOrganizations/{1}/users/Admin@{1}/msp'.format(configDir, org)]
        command = ["peer", "channel", "join",
                   "--blockpath", '/var/hyperledger/configs/{0}/{1}.block"'.format(context.composition.projectName, channelId)]
        if context.tls:
            setup.append('CORE_PEER_TLS_ROOTCERT_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/ca.crt'.format(configDir, org, peer))
            setup.append('CORE_PEER_TLS_CERT_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/server.crt'.format(configDir, org, peer))
            setup.append('CORE_PEER_TLS_KEY_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/server.key'.format(configDir, org, peer))
        count = 0
        output = "Error"

        # Try joining the channel 5 times with a 2 second delay between tries
        while count < 5 and "Error" in output:
            output = context.composition.docker_exec(setup+command, [peer])
            time.sleep(2)
            count = count + 1
            output = output[peer]

    print("[{0}]: {1}".format(" ".join(setup+command), output))
    return output


def invoke_chaincode(context, chaincode, orderers, peer, channelId=TEST_CHANNEL_ID):
    configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
    args = chaincode.get('args', '[]').replace('"', r'\"')
    peerParts = peer.split('.')
    org = '.'.join(peerParts[1:])
    setup = ["/bin/bash", "-c",
             '"CORE_PEER_MSPCONFIGPATH={0}/peerOrganizations/{1}/users/Admin@{1}/msp'.format(configDir, org)]
    command = ["peer", "chaincode", "invoke",
               "--name", chaincode['name'],
               "--ctor", r"""'{\"Args\": %s}'""" % (args),
               "--channelID", channelId,
               "--orderer", '{0}:7050"'.format(orderers[0])]
    if context.tls:
        setup.append('CORE_PEER_TLS_ROOTCERT_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/ca.crt'.format(configDir, org, peer))
        setup.append('CORE_PEER_TLS_CERT_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/server.crt'.format(configDir, org, peer))
        setup.append('CORE_PEER_TLS_KEY_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/server.key'.format(configDir, org, peer))
    output = context.composition.docker_exec(setup+command, [peer])
    print("Invoke[{0}]: {1}".format(" ".join(setup+command), str(output)))
    return output


def query_chaincode(context, chaincode, peer, channelId=TEST_CHANNEL_ID):
    configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
    peerParts = peer.split('.')
    org = '.'.join(peerParts[1:])
    args = chaincode.get('args', '[]').replace('"', r'\"')
    setup = ["/bin/bash", "-c",
             '"CORE_PEER_MSPCONFIGPATH={0}/peerOrganizations/{1}/users/Admin@{1}/msp'.format(configDir, org)]
    command = ["peer", "chaincode", "query",
               "--name", chaincode['name'],
               "--ctor", r"""'{\"Args\": %s}'""" % (args),
               "--channelID", channelId, '"']
    if context.tls:
        setup.append('CORE_PEER_TLS_ROOTCERT_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/ca.crt'.format(configDir, org, peer))
        setup.append('CORE_PEER_TLS_CERT_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/server.crt'.format(configDir, org, peer))
        setup.append('CORE_PEER_TLS_KEY_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/server.key'.format(configDir, org, peer))
    print("Query Exec command: {0}".format(" ".join(setup+command)))
    return context.composition.docker_exec(setup+command, [peer])


def get_orderers(context):
    orderers = []
    for container in context.composition.collectServiceNames():
        if container.startswith("orderer"):
            orderers.append(container)
    return orderers


def get_peers(context):
    peers = []
    for container in context.composition.collectServiceNames():
        if container.startswith("peer"):
            peers.append(container)
    return peers


def deploy_chaincode(context, chaincode, containers, channelId=TEST_CHANNEL_ID):
    for container in containers:
        assert container in context.composition.collectServiceNames(), "Unknown component '{0}'".format(container)

    orderers = get_orderers(context)
    peers = get_peers(context)
    assert orderers != [], "There are no active orderers in this network"

    chaincode.update({"orderers": orderers,
                      "channelID": channelId,
                      })
    create_channel(context, containers, orderers, channelId)
    #fetch_channel(context, peers, orderers, channelId)
    join_channel(context, peers, orderers, channelId)
    install_chaincode(context, chaincode, peers)
    instantiate_chaincode(context, chaincode, containers)

def get_initial_leader(context, org):
    if not hasattr(context, 'initial_leader'):
        context.initial_leader={}
    if org not in context.initial_leader:
        for container in get_peers(context):
            if ((org in container) and is_in_log(container, "Becoming a leader")):
                context.initial_leader[org]=container
                print("initial leader is "+context.initial_leader[org])
                return context.initial_leader[org]
        assert org in context.initial_leader.keys(), "Error: No gossip-leader found by looking at the logs, for "+org
    return context.initial_leader[org]

def get_initial_non_leader(context, org):
    if not hasattr(context, 'initial_non_leader'):
        context.initial_non_leader={}
    if org not in context.initial_non_leader:
        for container in get_peers(context):
            if ((org in container) and not is_in_log(container, "Becoming a leader")):
                context.initial_non_leader[org]=container
                print("initial non-leader is "+context.initial_non_leader[org])
                return context.initial_non_leader[org]
        assert org in context.initial_non_leader.keys(), "Error: No gossip-leader found by looking at the logs, for "+org
    return context.initial_non_leader[org]

def is_in_log(container, keyText):
    rc = subprocess.call(
            "docker logs "+container+" 2>&1 | grep "+"\""+keyText+"\"",
            shell=True)
    if rc==0:
        return True
    return False
