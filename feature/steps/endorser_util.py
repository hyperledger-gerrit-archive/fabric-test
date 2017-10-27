#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

import config_util
import json
import yaml
import os
import re
import remote_util
import shutil
import subprocess
import sys
import time
import common_util
import execjs

try:
    pbFilePath = "../feature-upgrade"
    sys.path.insert(0, pbFilePath)
    from peer import chaincode_pb2
except:
    print("ERROR! Unable to import the protobuf libraries from the ../feature-upgrade directory: {0}".format(sys.exc_info()[0]))
    sys.exit(1)

# The default channel ID
SYS_CHANNEL_ID = "behavesyschan"
TEST_CHANNEL_ID = "behavesystest"


class InterfaceBase:
    # The default channel ID
    SYS_CHANNEL_ID = "behavesyschan"
    TEST_CHANNEL_ID = "behavesystest"

    def get_orderers(self, context):
        orderers = []
        for container in context.composition.collectServiceNames():
            if container.startswith("orderer"):
                orderers.append(container)
        return orderers

    def get_peers(self, context):
        peers = []
        for container in context.composition.collectServiceNames():
            if container.startswith("peer"):
                peers.append(container)
        return peers

    def deploy_chaincode(self, context, path, args, name, language, peer, username, timeout, channel=TEST_CHANNEL_ID, version=0, policy=None):
        self.pre_deploy_chaincode(context, path, args, name, language, channel, version, policy)
        all_peers = self.get_peers(context)
        self.install_chaincode(context, all_peers, username)
        self.instantiate_chaincode(context, peer, username)
        self.post_deploy_chaincode(context, peer, timeout)

    def pre_deploy_chaincode(self, context, path, args, name, language, channelId=TEST_CHANNEL_ID, version=0, policy=None):
        orderers = self.get_orderers(context)
        peers = self.get_peers(context)
        assert orderers != [], "There are no active orderers in this network"

        context.chaincode={"path": path,
                           "language": language,
                           "name": name,
                           "version": str(version),
                           "args": args,
                           "orderers": orderers,
                           "channelID": channelId,
                           }
        if policy:
            context.chaincode['policy'] = policy

    def post_deploy_chaincode(self, context, peer, timeout):
        chaincode_container = "{0}-{1}-{2}-{3}".format(context.projectName,
                                                       peer,
                                                       context.chaincode['name'],
                                                       context.chaincode.get("version", 0))
        context.interface.wait_for_deploy_completion(context, chaincode_container, timeout)

    def channel_block_present(self, context, containers, channelId):
        ret = False
        configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
        output = context.composition.docker_exec(["ls", configDir], containers)
        for container in containers:
            if "{0}.tx".format(channelId) in output[container]:
                ret |= True
        print("Channel Block Present Result {0}".format(ret))
        return ret

    def get_initial_leader(self, context, org):
        if not hasattr(context, 'initial_leader'):
            context.initial_leader={}
        if org in context.initial_leader:
            return context.initial_leader[org]
        max_waittime=15
        waittime=5
        try:
            with common_util.Timeout(max_waittime):
                while org not in context.initial_leader:
                    for container in self.get_peers(context):
                        if ((org in container) and common_util.get_leadership_status(container)):
                            context.initial_leader[org]=container
                            print("initial leader is "+context.initial_leader[org])
                            break
                    time.sleep(waittime)
        finally:
            assert org in context.initial_leader, "Error: After polling for " + str(max_waittime) + " seconds, no gossip-leader found by looking at the logs, for "+org
        return context.initial_leader[org]

    def get_initial_non_leader(self, context, org):
        if not hasattr(context, 'initial_non_leader'):
            context.initial_non_leader={}
        if org in context.initial_non_leader:
            return context.initial_non_leader[org]
        if org not in context.initial_non_leader:
            for container in self.get_peers(context):
                if (org in container and  (not common_util.get_leadership_status(container))):
                    context.initial_non_leader[org]=container
                    print("initial non-leader is "+context.initial_non_leader[org])
                    return context.initial_non_leader[org]
        assert org in context.initial_non_leader, "Error: After polling for " + str(max_waittime) + " seconds, no gossip-non-leader found by looking at the logs, for "+org
        return context.initial_non_leader[org]

    def find_replace_multi_ordered(self, string, dictionary):
        # sort keys by length, in reverse order
        for item in sorted(dictionary.keys(), key = len, reverse = True):
            string = re.sub(item, str(dictionary[item]), string)
        return string

    def wait_for_deploy_completion(self, context, chaincode_container, timeout):
        pass

    def install_chaincode(self, context, peers, user="Admin"):
        return self.cli.install_chaincode(context, peers, user=user)

    def instantiate_chaincode(self, context, peer, user="Admin"):
        return self.cli.instantiate_chaincode(context, peer, user=user)

    def create_channel(self, context, orderer, channelId, user="Admin"):
        return self.cli.create_channel(context, orderer, channelId, user=user)

    def fetch_channel(self, context, peers, orderer, channelId=TEST_CHANNEL_ID, location=None, user="Admin", ext=""):
        return self.cli.fetch_channel(context, peers, orderer, channelId, location, user=user)

    def join_channel(self, context, peers, channelId, user="Admin"):
        return self.cli.join_channel(context, peers, channelId, user=user)

    def invoke_chaincode(self, context, chaincode, orderer, peer, channelId, targs="", user="User1"):
        # targs and user are optional parameters with defaults set if they are not included
        return self.cli.invoke_chaincode(context, chaincode, orderer, peer, channelId, targs, user)

    def query_chaincode(self, context, chaincode, peer, channelId, targs="", user="User1"):
        # targs and user are optional parameters with defaults set if they are not included
        return self.cli.query_chaincode(context, chaincode, peer, channelId, targs, user)

    def enrollUsersFabricCA(self, context):
        return self.cli.enrollUsersFabricCA(context)

    def addIdemixIdentities(self, context, user, passwd, role, org):
        return self.cli.addIdemixIdentities(context, user, passwd, role, org)

    def enrollCAadmin(self, context, node):
        return self.cli.enrollCAadmin(context, node)

    def revokeUserAndGenerateCRL(self, context, component, user, admin='Admin', adminpass='adminpw'):
        return self.cli.revokeUserAndGenerateCRL(context, component, user, admin=admin, adminpass=adminpass)

class ToolInterface(InterfaceBase):
    def __init__(self, context):
        remote_util.getNetworkDetails(context)

        # use CLI for non implemented functions
        self.cli = CLIInterface()

    def install_chaincode(self, context, peers, user="Admin"):
        results = {}
        for peer in peers:
            peer_name = context.networkInfo["nodes"][peer]["nodeName"]
            cmd = "node v1.0_sdk_tests/app.js installcc -i {0} -v 1 -p {1}".format(context.chaincode['name'],
                                                                    peer_name)
            print(cmd)
            results[peer] = subprocess.check_call(cmd.split(), env=os.environ)
        return results

    def instantiate_chaincode(self, context, peer="peer0.org1.example.com", user="Admin"):
        channel = str(context.chaincode.get('channelID', self.TEST_CHANNEL_ID))
        args = json.loads(context.chaincode["args"])
        print(args)
        peer_name = context.networkInfo["nodes"][peer]["nodeName"]
        cmd = "node v1.0_sdk_tests/app.js instantiatecc -c {0} -i {1} -v 1 -a {2} -b {3} -p {4}".format(channel,
                                                                                    context.chaincode["name"],
                                                                                    args[2],
                                                                                    args[4],
                                                                                    peer_name)
        print(cmd)
        return subprocess.check_call(cmd.split(), env=os.environ)

    def create_channel(self, context, orderer, channelId, user="Admin"):
        orderer_name = context.networkInfo["nodes"][orderer]["nodeName"]
        peer_name = context.networkInfo["nodes"]["peer0.org1.example.com"]["nodeName"]

        # Config Setup for tool
        cmd = "node v1.0_sdk_tests/app.js configtxn -c {0} -r {1}".format(channelId, "1,3")
        ret = subprocess.check_call(cmd.split(), env=os.environ)
        shutil.copyfile("{}.pb".format(channelId), "v1.0_sdk_tests/{}.pb".format(channelId))

        cmd = "node v1.0_sdk_tests/app.js createchannel -c {0} -o {1} -r {2} -p {3}".format(channelId,
                                                                      orderer_name,
                                                                      "1,3",
                                                                      peer_name)
        print(cmd)
        return subprocess.check_call(cmd.split(), env=os.environ)

    def join_channel(self, context, peers, channelId, user="Admin"):
        results = {}
        for peer in peers:
            peer_name = context.networkInfo["nodes"][peer]["nodeName"]
            cmd = "node v1.0_sdk_tests/app.js joinchannel -c {0} -p {1}".format(channelId, peer_name)
            print(cmd)
            results[peer] = subprocess.check_call(cmd.split(), env=os.environ)
        return results

    def invoke_chaincode(self, context, chaincode, orderer, peer, channelId, targs="", user="User1"):
        # targs and user are optional parameters with defaults set if they are not included
        args = json.loads(chaincode["args"])
        peer_name = context.networkInfo["nodes"][peer]["nodeName"]
        cmd = "node v1.0_sdk_tests/app.js invoke -c {0} -i {1} -v 1 -p {2} -m {3}".format(channelId,
                                                                         chaincode["name"],
                                                                         peer_name,
                                                                         args[-1])
        print(cmd)
        return {peer: subprocess.check_call(cmd.split(), env=os.environ)}

    def query_chaincode(self, context, chaincode, peer, channelId, targs="", user="User1"):
        # targs and user are optional parameters with defaults set if they are not included
        peer_name = context.networkInfo["nodes"][peer]["nodeName"]
        cmd = "node v1.0_sdk_tests/app.js query -c {0} -i {1} -v 1 -p {2}".format(channelId,
                                                                   chaincode["name"],
                                                                   peer_name)
        print(cmd)
        return {peer: subprocess.check_call(cmd.split(), env=os.environ)}

    def update_chaincode(self, context, chaincode, peer, channelId, user="Admin"):
        peer_name = context.networkInfo["nodes"][peer]["nodeName"]


class SDKInterface(InterfaceBase):
    def __init__(self, context, language):
        if context.remote:
            remote_util.getNetwork()
        self.networkConfigFile = self.generateNetworkConfig(context)

        # use CLI for non implemented functions
        self.cli = CLIInterface()
        self.context = context

        if language.lower() == "nodejs":
            self.initializeNode()
        elif language.lower() == "java":
            self.initializeJava()
        else:
            raise "Language {} is not supported in the test framework yet.".format(language)

    def generateNetworkConfig(self, context):
        with open("./configs/network-config.json", "r") as fd:
            networkConfig = fd.read()

        grpcType = "grpc"
        if context.tls:
            grpcType = "grpcs"
        networkConfigFile = "{0}/configs/{1}/network-config.json".format(os.path.abspath('.'),
                                                                         context.projectName)

        with open("{1}/configs/{0}/ordererOrganizations/example.com/ca/ca.example.com-cert.pem".format(context.projectName, os.path.abspath('.')), "r") as fd:
              certs = fd.read().replace("\n", "\\r\\n")

        for org in ["org1.example.com", "org2.example.com"]:
            with open("{2}/configs/{0}/peerOrganizations/{1}/ca/ca.{1}-cert.pem".format(context.projectName, org, os.path.abspath('.')), "r") as fd:
                  certs += fd.read().replace("\n", "\\r\\n")

        print("CACerts: {}".format(str(certs)))

        with open(networkConfigFile, "w+") as fd:
            structure = {"config": "{0}/configs/{1}".format(os.path.abspath('.'),
                                                            context.projectName),
                         "tls": common_util.convertBoolean(context.tls),
                         "grpcType": grpcType,
                         "cacerts": certs,
                         "networkId": context.projectName}
            updated = json.loads(networkConfig % (structure))
            fd.write(json.dumps(updated, indent=2))
        return networkConfigFile

    def initializeNode(self):
        shutil.rmtree("./node_modules", ignore_errors=True)
        shutil.rmtree("./package-lock.json", ignore_errors=True)
        shutil.copyfile("package.json", "../../../package.json")
        node = execjs.get(execjs.runtime_names.Node)
        print("node info: {}".format(node.name))
        npminstall = subprocess.check_output(["npm install --silent"],
                                            env=os.environ,
                                            cwd="../../..",
                                            shell=True)
        print("npm install: {}".format(npminstall))
        shutil.copytree("../../../node_modules", "./node_modules")
        self.__class__ = NodeSDKInterface

    def initializeJava(self):
        self.__class__ = JavaSDKInterface
        orgDirs = ["./configs/{0}/ordererOrganizations/example.com/users".format(self.context.projectName),
                   "./configs/{0}/peerOrganizations/org1.example.com/users".format(self.context.projectName),
                   "./configs/{0}/peerOrganizations/org2.example.com/users".format(self.context.projectName)]
        for orgDir in orgDirs:
            l = os.listdir(orgDir)
            for d in l:
                shutil.rmtree("../../peer-javasdk-test-tool/users/{0}".format(d), ignore_errors=True)
                shutil.copytree("{0}/{1}".format(orgDir, d), "../../peer-javasdk-test-tool/users/{0}".format(d))
#        shutil.copytree("./configs/{0}/peerOrganizations/org1.example.com/users".format(self.context.projectName), "../../peer-javasdk-test-tool/users/.")
#        shutil.copytree("./configs/{0}/peerOrganizations/org2.example.com/users".format(self.context.projectName), "../../peer-javasdk-test-tool/users/.")

    def reformat_chaincode(self, chaincode, channelId):
        reformatted = yaml.safe_load(chaincode.get('args', '[]'))
        function = reformatted.pop(0)
        chaincode['fcn'] = str(function)
        chaincode['args'] = reformatted
        chaincode['channelId'] = str(channelId)
        return chaincode

    def invoke_chaincode(self, context, chaincode, orderer, peer, channelId=TEST_CHANNEL_ID, targs="", user="User1"):
        # channelId, targs and user are optional parameters with defaults set if they are not included
        peerParts = peer.split('.')
        org = '.'.join(peerParts[1:])
        result = self.invoke_func(chaincode, channelId, user, org, [peer], orderer)
        print("Invoke: {}".format(result))
        return {peer: result}
        #return result

    def query_chaincode(self, context, chaincode, peer, channelId=TEST_CHANNEL_ID, targs="", user="User1"):
        # targs and user are optional parameters with defaults set if they are not included
        peerParts = peer.split('.')
        org = '.'.join(peerParts[1:])
        print("Class:", self.__class__)
        result = self.query_func(chaincode, channelId, user, org, [peer])
        print("Query Result: {}".format(result))
        return {peer: result}

    def wait_for_deploy_completion(self, context, chaincode_container, timeout):
        if context.remote:
            time.sleep(30)

        containers = subprocess.check_output(["docker ps -a"], shell=True)
        try:
            with common_util.Timeout(timeout):
                while chaincode_container not in containers:
                    containers = subprocess.check_output(["docker ps -a"], shell=True)
                    time.sleep(1)
        finally:
            assert chaincode_container in containers, "The expected chaincode container {0} is not running\n{1}".format(chaincode_container, containers)

        # Allow time for chaincode initialization to complete
        time.sleep(15)


class NodeSDKInterface(SDKInterface):
    def invoke_func(self, chaincode, channelId, user, org, peers, orderer):
        reformatted = self.reformat_chaincode(chaincode, channelId)
        print("Chaincode", chaincode)
        orgName = org.title().replace('.', '')

        with open("./sdk/node/invoke.js", "r") as fd:
            invoke_text = fd.read()
        invoke_func = execjs.compile(invoke_text)
        return invoke_func.call("invoke", "{0}@{1}".format(user, org), orgName, reformatted, peers, orderer, self.networkConfigFile)

    def query_func(self, chaincode, channelId, user, org, peers):
        print("Chaincode", chaincode)
        reformatted = self.reformat_chaincode(chaincode, channelId)
        orgName = org.title().replace('.', '')
        print("Query Info: {0}@{1}, {2}, {3}, {4}".format(user, org, orgName, reformatted, peers))

        with open("./sdk/node/query.js", "r") as fd:
            query_text = fd.read()
        query_func = execjs.compile(query_text)
        return query_func.call("query", "{0}@{1}".format(user, org), orgName, reformatted, peers, self.networkConfigFile)


class JavaSDKInterface(SDKInterface):
    def invoke_func(self, chaincode, channelId, user, org, peers, orderer):
        print("Chaincode", chaincode)
        result = {}
        reformatted = self.reformat_chaincode(chaincode, channelId)
        password = self.context.users.get(user, None)
        if password is None:
            if "Admin" in user:
                password = "adminpw"
            elif "User" in user:
                password = "{}pw".format(user.lower())
        for peer in peers:
            inputs = {'peer': peer,
                      'org': org,
                      'orgName': org.title().replace('.', ''),
                      #'user': "{0}@{1}".format(user, org),
                      'user': user,
                      'password': password,
                      'orderer': orderer,
                      #'config': self.networkConfigFile,
                      'config': "{0}/configs/{1}".format(os.path.abspath('.'), self.context.projectName),
                      #'cacert': "./configs/{0}/peerOrganizations/{1}/ca/ca.{1}-cert.pem".format(self.context.projectName, org),
                      'cacert': "{1}/configs/{0}/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem".format(self.context.projectName, os.path.abspath('.')),
                      'srvcert': "./configs/{0}/peerOrganizations/{1}/peers/peer0.{1}/tls/server.crt".format(self.context.projectName, org),
                      'channel': channelId,
                      'name': chaincode.get("name", "mycc"),
                      'func': reformatted["fcn"],
                      'args': reformatted["args"],
                      }
            invoke_inputs = '-n {peer} -i 127.0.0.1 -p 7051 -r {org} -c {config} -a {cacert} -s {srvcert} -d {orderer} -h {channel} -m {name} -f {func} -g {args} -u {user} -w {password}'.format(**inputs)
            invoke_call = 'java -jar sdk/java/peer-javasdk.jar -o invoke ' + invoke_inputs
            #invoke_call = 'java -jar target/peer-javasdk-1.0-jar-with-dependencies-exclude-resources.jar -o invoke' + invoke_inputs
            result[peer] = subprocess.check_output(invoke_call, shell=True)
        return result

    def query_func(self, chaincode, channelId, user, org, peers):
        print("Chaincode", chaincode)

        result = {}
        reformatted = self.reformat_chaincode(chaincode, channelId)
        passInfo = self.context.users.get(user, None)
        if passInfo is None:
            if "Admin" in user:
                password = "adminpw"
            elif "User" in user:
                password = "{}pw".format(user.lower())
        else:
            password = passInfo["password"]
        for peer in peers:
            inputs = {'peer': peer,
                      'org': org,
                      'orgName': org.title().replace('.', ''),
                      #'user': "{0}@{1}".format(user, org),
                      'user': user,
                      'password': password,
                      'orderer': "orderer0.example.com",
                      #'config': self.networkConfigFile,
                      'config': "{0}/configs/{1}".format(os.path.abspath('.'), self.context.projectName),
                      #'cacert': "{2}/configs/{0}/peerOrganizations/{1}/ca/ca.{1}-cert.pem".format(self.context.projectName, org, os.path.abspath('.')),
                      'cacert': "{1}/configs/{0}/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem".format(self.context.projectName, os.path.abspath('.')),
                      'srvcert': "{2}/configs/{0}/peerOrganizations/{1}/peers/peer0.{1}/tls/server.crt".format(self.context.projectName, org, os.path.abspath('.')),
                      'channel': channelId,
                      'name': chaincode.get("name", "mycc"),
                      'func': reformatted["fcn"],
                      'args': reformatted["args"],
                      }
            print("Inputs", inputs)
            #query_inputs = '"{peer}" "127.0.0.1" "7051" ccquery "{orgName}" "0" "false" "{config}" "{cacert}" "{srvcert}" "{channel}" "{name}" "{func}" "{args}"'.format(**inputs)
            query_inputs = '-n {peer} -i 127.0.0.1 -p 7051 -r {org} -c {config} -a {cacert} -s {srvcert} -d {orderer} -h {channel} -m {name} -f {func} -g {args} -u {user} -w {password}'.format(**inputs)
            query_call = 'java -jar sdk/java/peer-javasdk.jar -o query ' + query_inputs
            result[peer] = subprocess.check_output(query_call, shell=True)
        return result


class CLIInterface(InterfaceBase):

    def get_env_vars(self, context, peer="peer0.org1.example.com", user="Admin", includeAll=True):
        configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
        peerParts = peer.split('.')
        org = '.'.join(peerParts[1:])
        setup = ["/bin/bash", "-c",
                 '"CORE_PEER_MSPCONFIGPATH={0}/peerOrganizations/{2}/users/{1}@{2}/msp'.format(configDir, user, org)]

        if includeAll:
            setup += ['CORE_PEER_LOCALMSPID={0}'.format(org),
                      'CORE_PEER_ID={0}'.format(peer),
                      'CORE_PEER_ADDRESS={0}:7051'.format(peer)]

        # Only pull the env vars specific to the peer
        if peer in context.composition.environ.keys():
            for key, value in context.composition.environ[peer].items():
                setup.append("{0}={1}".format(key, value))

        if context.tls and "CORE_PEER_TLS_CERT_FILE" not in setup:
            setup += ['CORE_PEER_TLS_ROOTCERT_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/ca.crt'.format(configDir, org, peer),
                      'CORE_PEER_TLS_CERT_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/server.crt'.format(configDir, org, peer),
                      'CORE_PEER_TLS_KEY_FILE={0}/peerOrganizations/{1}/peers/{2}/tls/server.key'.format(configDir, org, peer)]

        return setup

    def get_chaincode_deploy_spec(self, projectDir, ccType, path, name, args):
        subprocess.call(["peer", "chaincode", "package",
                         "-n", name,
                         "-c", '{"Args":{0}}'.format(args),
                         "-p", path,
                         "configs/{0}/test.file".format(projectDir)], shell=True)
        ccDeploymentSpec = chaincode_pb2.ChaincodeDeploymentSpec()
        with open("test.file", 'rb') as f:
            ccDeploymentSpec.ParseFromString(f.read())
        return ccDeploymentSpec

    def install_chaincode(self, context, peers, user="Admin"):
        configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
        output = {}
        for peer in peers:
            peerParts = peer.split('.')
            org = '.'.join(peerParts[1:])
            setup = self.get_env_vars(context, peer, user=user)
            command = ["peer", "chaincode", "install",
                       "--name",context.chaincode['name'],
                       "--lang", context.chaincode['language'],
                       "--version", str(context.chaincode.get('version', 0)),
                       "--path", context.chaincode['path']]
            if context.tls:
                command = command + ["--tls",
                                     "--cafile",
                                     '{0}/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem'.format(configDir)]
            if hasattr(context, "mutual_tls") and context.mutual_tls:
                command = command + ["--clientauth",
                                     "--certfile",
                                     '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.crt'.format(configDir, org, user),
                                     "--keyfile",
                                     '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.key'.format(configDir, org, user)]
            if "orderers" in context.chaincode:
                command = command + ["--orderer", 'orderer0.example.com:7050']
            if "user" in context.chaincode:
                command = command + ["--username", context.chaincode["user"]]
            command.append('"')
            ret = context.composition.docker_exec(setup+command, ['cli'])
            output[peer] = ret['cli']
        print("[{0}]: {1}".format(" ".join(setup + command), output))
        return output

    def instantiate_chaincode(self, context, peer="peer0.org1.example.com", user="Admin"):
        configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
        args = context.chaincode.get('args', '[]').replace('"', r'\"')
        output = {}
        peerParts = peer.split('.')
        org = '.'.join(peerParts[1:])
        setup = self.get_env_vars(context, peer, user=user)
        command = ["peer", "chaincode", "instantiate",
                   "--name", context.chaincode['name'],
                   "--version", str(context.chaincode.get('version', 0)),
                   "--lang", context.chaincode['language'],
                   "--channelID", str(context.chaincode.get('channelID', self.TEST_CHANNEL_ID)),
                   "--ctor", r"""'{\"Args\": %s}'""" % (args)]
        if context.tls:
            command = command + ["--tls",
                                 common_util.convertBoolean(context.tls),
                                 "--cafile",
                                 '{0}/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem'.format(configDir)]
        if hasattr(context, "mutual_tls") and context.mutual_tls:
            command = command + ["--clientauth",
                                 "--certfile",
                                 '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.crt'.format(configDir, org, user),
                                 "--keyfile",
                                 '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.key'.format(configDir, org, user)]
        if "orderers" in context.chaincode:
            command = command + ["--orderer", 'orderer0.example.com:7050']
        if "user" in context.chaincode:
            command = command + ["--username", context.chaincode["user"]]
        if context.chaincode.get("policy", None) is not None:
            command = command + ["--policy", context.chaincode["policy"].replace('"', r'\"')]
        command.append('"')

        output[peer] = context.composition.docker_exec(setup + command, [peer])
        print("[{0}]: {1}".format(" ".join(setup + command), output))
        return output

    def create_channel(self, context, orderer, channelId=TEST_CHANNEL_ID, user="Admin"):
        configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
        setup = self.get_env_vars(context, "peer0.org1.example.com", user=user)
        # Ideally this would NOT be a 5 minute timeout, but more like a 2 minute timeout.
        timeout = 300 + common_util.convertToSeconds(context.composition.environ.get('CONFIGTX_ORDERER_BATCHTIMEOUT', '0s'))
        command = ["peer", "channel", "create",
                   "--file", "/var/hyperledger/configs/{0}/{1}.tx".format(context.composition.projectName, channelId),
                   "--channelID", channelId,
                   "--timeout", "{}s".format(timeout),
                   "--orderer", '{0}:7050'.format(orderer)]
        if context.tls:
            command = command + ["--tls",
                                 common_util.convertBoolean(context.tls),
                                 "--cafile",
                                 '{0}/ordererOrganizations/example.com/orderers/{1}/msp/tlscacerts/tlsca.example.com-cert.pem'.format(configDir, orderer)]
        if hasattr(context, "mutual_tls") and context.mutual_tls:
            org = "org1.example.com"
            command = command + ["--clientauth",
                                 "--certfile",
                                 '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.crt'.format(configDir, org, user),
                                 "--keyfile",
                                 '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.key'.format(configDir, org, user)]

        command.append('"')

        output = context.composition.docker_exec(setup+command, ['cli'])
        print("[{0}]: {1}".format(" ".join(setup+command), output))
        if "SERVICE_UNAVAILABLE" in output['cli']:
            time.sleep(5)
            print("Received: {0}, Trying again...".format(output['cli']))
            output = context.composition.docker_exec(setup+command, ['cli'])
        assert "Error:" not in output, "Unable to successfully create channel {}".format(channelId)

        return output

    def fetch_channel(self, context, peers, orderer, channelId=TEST_CHANNEL_ID, location=None, user="Admin", ext="", block=""):
        configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
        if not location:
            location = configDir

        if not ext:
            ext = "block"

        output = {}
        for peer in peers:
            setup = self.get_env_vars(context, peer, includeAll=False, user=user)
            command = ["peer", "channel", "fetch", "config"]
            if block:
                command = ["peer", "channel", "fetch", block]
            command += ["{0}/{1}.{2}".format(location, channelId, ext),
                        "--channelID", channelId,
                        "--orderer", '{0}:7050'.format(orderer)]
            if context.tls:
                command = command + ["--tls",
                                     "--cafile",
                                     '{0}/ordererOrganizations/example.com/orderers/{1}/msp/tlscacerts/tlsca.example.com-cert.pem'.format(configDir, orderer)]
            if hasattr(context, "mutual_tls") and context.mutual_tls:
                peerParts = peer.split('.')
                org = '.'.join(peerParts[1:])
                command = command + ["--clientauth",
                                     "--certfile",
                                     '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.crt'.format(configDir, org, user),
                                     "--keyfile",
                                     '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.key'.format(configDir, org, user)]

            command.append('"')

            output.update(context.composition.docker_exec(setup+command, [peer]))
            print("[{0}]: {1}".format(" ".join(setup+command), output))
        return output

    def join_channel(self, context, peers, channelId=TEST_CHANNEL_ID, user="Admin"):
        configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)

        for peer in peers:
            peerParts = peer.split('.')
            org = '.'.join(peerParts[1:])
            setup = self.get_env_vars(context, peer, user=user)
            command = ["peer", "channel", "join",
                       "--blockpath", '/var/hyperledger/configs/{0}/{1}.block"'.format(context.composition.projectName, channelId)]
            count = 0
            output = "Error"

            # Try joining the channel 5 times with a 2 second delay between tries
            while count < 5 and "Error" in output:
                output = context.composition.docker_exec(setup+command, [peer])
                time.sleep(2)
                count = count + 1
                output = output[peer]

        print("[{0}]: {1}".format(" ".join(setup+command), output))
        assert "Error: genesis block file not found open " not in output, "Unable to find the genesis block file {0}.block".format(channelId)

        return output

    def update_channel(self, context, peers, channelId=TEST_CHANNEL_ID, orderer="orderer0.example.com", block_filename="update.pb", user="Admin"):
        configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)

        # peer channel update -f org3_update_in_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050 --tls --cafile $ORDERER_CA
        for peer in peers:
            peerParts = peer.split('.')
            org = '.'.join(peerParts[1:])
            setup = self.get_env_vars(context, peer, includeAll=False, user=user)
            command = ["peer", "channel", "update",
                       "--file", block_filename,
                       "--channelID", channelId,
                       "--orderer", '{0}:7050'.format(orderer)]
            if context.tls:
                command = command + ["--tls",
                                     "--cafile",
                                     '{0}/ordererOrganizations/example.com/orderers/{1}/msp/tlscacerts/tlsca.example.com-cert.pem'.format(configDir, orderer)]
            if hasattr(context, "mutual_tls") and context.mutual_tls:
                command = command + ["--clientauth",
                                     "--certfile",
                                     '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.crt'.format(configDir, org, user),
                                     "--keyfile",
                                     '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.key'.format(configDir, org, user)]

            command.append('"')
            output = context.composition.docker_exec(setup+command, [peer])
        print("[{0}]: {1}".format(" ".join(setup+command), output))
        return output

    def sign_channel(self, context, peers, block_filename="update.pb", user="Admin"):
        # peer channel signconfigtx -f org3_update_in_envelope.pb
        for peer in peers:
            peerParts = peer.split('.')
            org = '.'.join(peerParts[1:])
            setup = self.get_env_vars(context, peer, user=user)
            command = ["peer", "channel", "signconfigtx",
                       "--file", '{}"'.format(block_filename)]
            output = context.composition.docker_exec(setup+command, [peer])
        print("[{0}]: {1}".format(" ".join(setup+command), output))
        return output

    def upgrade_chaincode(self, context, orderer, peer, channelId=TEST_CHANNEL_ID, user="Admin"):
        configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
        setup = self.get_env_vars(context, peer, user=user)
        command = ["peer", "chaincode", "upgrade",
                   "--name", context.chaincode['name'],
                   "--version", str(context.chaincode.get('version', 1)),
                   "--channelID", str(context.chaincode.get('channelID', channelId))]
        if context.chaincode["args"]:
            command = command + ["--ctor", r"""'{\"Args\": %s}'""" % (str(context.chaincode["args"].replace('"', r'\"')))]
        if context.tls:
            command = command + ["--tls",
                                 "--cafile",
                                 '{0}/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem'.format(configDir)]
        if hasattr(context, "mutual_tls") and context.mutual_tls:
            peerParts = peer.split('.')
            org = '.'.join(peerParts[1:])
            command = command + ["--clientauth",
                                 "--certfile",
                                 '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.crt'.format(configDir, org, user),
                                 "--keyfile",
                                 '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.key'.format(configDir, org, user)]
        if "orderers" in context.chaincode:
            command = command + ["--orderer", '{}:7050'.format(orderer)]
        if "user" in context.chaincode:
            command = command + ["--username", context.chaincode["user"]]
        if context.chaincode.get("policy", None) is not None:
            command = command + ["--policy", context.chaincode["policy"].replace('"', r'\"')]

        command.append('"')
        output = context.composition.docker_exec(setup+command, ['peer0.org1.example.com'])
        print("[{0}]: {1}".format(" ".join(setup + command), output))
        return output

    def invoke_chaincode(self, context, chaincode, orderer, peer, channelId=TEST_CHANNEL_ID, targs="", user="User1"):
        # channelId, targs and user are optional parameters with defaults set if they are not included
        configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
        args = chaincode.get('args', '[]').replace('"', r'\"')
        setup = self.get_env_vars(context, peer, user=user)
        command = ["peer", "chaincode", "invoke",
                   "--name", chaincode['name'],
                   "--ctor", r"""'{\"Args\": %s}'""" % (args),
                   "--channelID", channelId]
        if context.tls:
            command = command + ["--tls",
                                 "--cafile",
                                 '{0}/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem'.format(configDir)]
        if hasattr(context, "mutual_tls") and context.mutual_tls:
            peerParts = peer.split('.')
            org = '.'.join(peerParts[1:])
            command = command + ["--clientauth",
                                 "--certfile",
                                 '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.crt'.format(configDir, org, user),
                                 "--keyfile",
                                 '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.key'.format(configDir, org, user)]
        if targs:
            #to escape " so that targs are compatible with cli command
            targs = targs.replace('"', r'\"')
            command = command + ["--transient", targs]

        command = command + ["--orderer", '{0}:7050'.format(orderer)]
        command.append('"')
        output = context.composition.docker_exec(setup+command, [peer])
        print("Invoke[{0}]: {1}".format(" ".join(setup+command), str(output)))
        output = self.retry(context, output, peer, setup, command)
        return output

    def query_chaincode(self, context, chaincode, peer, channelId=TEST_CHANNEL_ID, targs="", user="User1"):
        # channelId, targs and user are optional parameters with defaults set if they are not included
        configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
        peerParts = peer.split('.')
        org = '.'.join(peerParts[1:])
        args = chaincode.get('args', '[]').replace('"', r'\"')
        setup = self.get_env_vars(context, peer, user=user)
        command = ["peer", "chaincode", "query",
                   "--name", chaincode['name'],
                   "--ctor", r"""'{\"Args\": %s}'""" % (str(args)), # This should work for rich queries as well
                   "--channelID", channelId]
        if targs:
            #to escape " so that targs are compatible with cli command
            targs = targs.replace('"', r'\"')
            command = command +["--transient", targs]

        if context.tls:
            command = command + ["--tls",
                                 "--cafile",
                                 '{0}/peerOrganizations/{1}/tlsca/tlsca.{1}-cert.pem'.format(configDir, org),
                                 "--certfile",
                                 '{0}/peerOrganizations/{1}/users/{2}@{1}/tls/client.crt'.format(configDir, org, user)]
        command.append('"')
        result = context.composition.docker_exec(setup+command, [peer])
        print("Query Exec command: {0}".format(" ".join(setup+command)))
        result = self.retry(context, result, peer, setup, command)
        print("Query Result: {0}".format(result))
        return result

    def enrollCAadmin(self, context, node, admin="Admin", passwd="adminpw"):
        org = node.split(".", 1)[1]
        userpass = context.composition.getEnvFromContainer("ca.{}".format(org), 'BOOTSTRAP_USER_PASS')
        #url = "https://{0}@ca.{1}:7054".format(userpass, org)
        url = "https://{0}:{2}@ca.{1}:7054".format(admin, org, passwd)
        output = context.composition.docker_exec(["fabric-ca-client enroll -d -u {0} -M /var/hyperledger/msp --caname ca.{1} --csr.cn ca.{1} --tls.certfiles /var/hyperledger/msp/cacerts/ca.{1}-cert.pem".format(url, org)], [node])
        print("Output Enroll: {}".format(output))

    def registerUser(self, context, user, org, passwd, role, component):
        command = "fabric-ca-client register -d --id.name {0} --id.secret {2} --tls.certfiles /var/hyperledger/msp/cacerts/ca.{1}-cert.pem".format(user, org, passwd)
        if role.lower() == u'admin' and component.startswith("orderer"):
            # Register on orderers
            command += ''' --id.attrs '"admin=true:ecert"' '''

        elif role.lower() == u'admin':
            command += ''' --id.attrs '"hf.Registrar.Roles=peer,client"' --id.attrs hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert'''

        context.composition.environ["FABRIC_CA_CLIENT_HOME"] = "/var/hyperledger/users/{0}@{1}".format(user, org)
        output = context.composition.docker_exec([command], [component])
        print("user register: {}".format(output))

    def enrollUser(self, context, user, org, passwd, enrollType, component, orgType):
        fca = 'ca.{}'.format(org)
        adminUser = context.composition.getEnvFromContainer(fca, "BOOTSTRAP_USER_PASS")
        if orgType == "peerOrganizations":
            command = "fabric-ca-client enroll -d --enrollment.profile tls -u https://{0}:{1}@{3}:7054 -M /var/hyperledger/users/{0}@{2}/tls --csr.hosts {4} --enrollment.type {5} --tls.certfiles /var/hyperledger/configs/{6}/{7}/{2}/ca/ca.{2}-cert.pem".format(user, passwd, org, fca, component, enrollType, context.projectName, orgType)
        else:
            command = "fabric-ca-client enroll -d --enrollment.profile tls -u https://{0}:{1}@{3}:7054 -M /var/hyperledger/users/{0}@{2}/tls --csr.hosts {4} --enrollment.type {5} --tls.certfiles /var/hyperledger/configs/{6}/{2}/ca/ca.{2}-cert.pem".format(user, passwd, org, fca, component, enrollType, orgType)
        output = context.composition.docker_exec([command], [component])
        print("Output: {}".format(output))

        if orgType == "peerOrganizations":
            command = "fabric-ca-client certificate list -d --id {0} --store /var/hyperledger/users/{0}@{1}/tls/ --caname {3} --csr.cn {3} --tls.certfiles /var/hyperledger/configs/{2}/{4}/{1}/ca/ca.{1}-cert.pem".format(user, org, context.projectName, fca, orgType)
        else:
            command = "fabric-ca-client certificate list -d --id {0} --store /var/hyperledger/users/{0}@{1}/tls/ --caname {2} --csr.cn {2} --tls.certfiles /var/hyperledger/configs/{3}/{1}/ca/ca.{1}-cert.pem".format(user, org, fca, orgType)
        output = context.composition.docker_exec([command], [component])
        print("Cert Output: {}".format(output))

    def enrollUsersFabricCA(self, context):
        configDir = "/var/hyperledger/configs/{0}".format(context.composition.projectName)
        for user in context.users.keys():
            org = context.users[user]['organization']
            passwd = context.users[user]['password']
            role = context.users[user].get('role', "user")
            enrollType = context.users[user].get('certType', "x509")
            peer = 'peer0.{}'.format(org)

            if role.lower() == u'admin':
                self.enrollCAadmin(context, "orderer0.example.com")
                self.registerUser(context, user, "example.com", passwd, role, "orderer0.example.com")
                self.enrollUser(context, user, "example.com", passwd, enrollType, "orderer0.example.com", "ordererOrganizations")
                self.placeCertsInDirStruct(context, user, "example.com", "orderer0.example.com", "ordererOrganizations")

                self.enrollCAadmin(context, "peer0.org2.example.com")
                self.registerUser(context, user, "org2.example.com", passwd, role, "peer0.org2.example.com")
                self.enrollUser(context, user, "org2.example.com", passwd, enrollType, "peer0.org2.example.com", "peerOrganizations")
                self.placeCertsInDirStruct(context, user, "org2.example.com", "peer0.org2.example.com", "peerOrganizations")

            # Enroll (login) admin first
            self.enrollCAadmin(context, peer)

            self.registerUser(context, user, org, passwd, role, peer)
            self.enrollUser(context, user, org, passwd, enrollType, peer, "peerOrganizations")
            if enrollType == u'idemix':
                self.addIdemixIdentities(context, user, passwd, role, org)

            # Place the certificates in the set directory structure
            self.placeCertsInDirStruct(context, user, org, peer, "peerOrganizations")

    def placeCertsInDirStruct(self, context, user, org, peer, orgType):
        fca = 'ca.{}'.format(org)

        # Ensure that the owner of all of the user directories are the same
        print("Checking file ownership: /var/hyperledger/users/{0}@{1} ...".format(user, org))
        output = context.composition.docker_exec(['stat -c "%u %g" /var/hyperledger/users/Admin@{0}'.format(org)], [peer])
        out = output[peer].strip().split(" ")
        print("Existing stat:: {}".format(out))
        output = context.composition.docker_exec(['stat -c "%u %g" /var/hyperledger/users/{0}@{1}'.format(user, org)], [peer])
        new = output[peer].strip().split(" ")
        print("New stat:: {}".format(new))
        if new[0] != out[0]:
            context.printEnvWarning = True
            output = context.composition.docker_exec(['chown -R {2}:{3} /var/hyperledger/users/{0}@{1}'.format(user, org, out[0], out[1])], [peer])

        orgType = "ordererOrganizations"
        if org.startswith("org"):
            orgType = "peerOrganizations"
        os.mkdir("configs/{2}/{3}/{1}/users/{0}@{1}/msp".format(user, org, context.projectName, orgType))
        os.mkdir("configs/{2}/{3}/{1}/users/{0}@{1}/msp/signcerts".format(user, org, context.projectName, orgType))
        os.mkdir("configs/{2}/{3}/{1}/users/{0}@{1}/msp/keystore".format(user, org, context.projectName, orgType))
        os.mkdir("configs/{2}/{3}/{1}/users/{0}@{1}/msp/admincerts".format(user, org, context.projectName, orgType))

        shutil.copy("configs/{2}/{3}/{1}/users/{0}@{1}/tls/{0}.pem".format(user, org, context.projectName, orgType),
                    "configs/{2}/{3}/{1}/users/{0}@{1}/tls/client.crt".format(user, org, context.projectName, orgType))
        shutil.copy("configs/{2}/{3}/{1}/users/{0}@{1}/tls/signcerts/cert.pem".format(user, org, context.projectName, orgType),
                    "configs/{2}/{3}/{1}/users/{0}@{1}/msp/signcerts/{0}@{1}-cert.pem".format(user, org, context.projectName, orgType))
        keyfile = os.listdir("configs/{2}/{3}/{1}/users/{0}@{1}/tls/keystore/".format(user, org, context.projectName, orgType))[0]
        shutil.copy("configs/{2}/{4}/{1}/users/{0}@{1}/tls/keystore/{3}".format(user, org, context.projectName, keyfile, orgType),
                    "configs/{2}/{3}/{1}/users/{0}@{1}/tls/client.key".format(user, org, context.projectName, orgType))
        shutil.copy("configs/{2}/{4}/{1}/users/{0}@{1}/tls/keystore/{3}".format(user, org, context.projectName, keyfile, orgType),
                    "configs/{2}/{4}/{1}/users/{0}@{1}/msp/keystore/{3}".format(user, org, context.projectName, keyfile, orgType))

        shutil.copy("configs/{2}/{3}/{1}/users/{0}@{1}/msp/signcerts/{0}@{1}-cert.pem".format(user, org, context.projectName, orgType),
                    "configs/{2}/{3}/{1}/users/{0}@{1}/msp/admincerts/{0}@{1}-cert.pem".format(user, org, context.projectName, orgType))

        command = "fabric-ca-client getcacert -d -u https://{0}:7054 -M /var/hyperledger/users/{1}@{2}/msp --tls.certfiles /var/hyperledger/msp/cacerts/ca.{2}-cert.pem".format(fca, user, org)
        output = context.composition.docker_exec([command], [peer])
        print("CACert Output: {}".format(output))
        output = context.composition.docker_exec(['chown -R {2}:{3} /var/hyperledger/users/{0}@{1}'.format(user, org, out[0], out[1])], [peer])

    def addIdemixIdentities(self, context, user, passwd, role, org):
        peer = 'peer0.{}'.format(org)
        d = {"passwd": passwd, "role": role, "org": org, "username": user, "attrib": [{"name": "hf.Revoker", "value": "true"}]}
        if role.lower() == u'admin':
            d["attrib"].append({"name": "admin", "value": "true:ecert"})
        commandStr = "fabric-ca-client identity add {0} --json '{\"secret\": \"passwd\", \"type\": \"user\", \"affiliation\": \"org\", \"max_enrollments\": 1, \"attrs\": attrib}' --id.name username --id.secret passwd --tls.certfiles /var/hyperledger/msp/cacerts/ca.org-cert.pem"
        command = self.find_replace_multi_ordered(commandStr, d)
        output = context.composition.docker_exec([command], [peer])
        print("Idemix Output: {}".format(output))

        output = context.composition.docker_exec(["fabric-ca-client identity list"], [peer])
        print("Ident List: {}".format(output))


    def revokeUserAndGenerateCRL(self, context, component, user, admin='Admin', adminpass='adminpw'):
        org = component.split(".", 1)[1]
        updated_env = config_util.updateEnviron(context)
        updated_env['FABRIC_CA_CLIENT_HOME'] = "/var/hyperledger/users/Admin@{}/msp/crls/crl.pem".format(org)
        self.enrollCAadmin(context, component, admin, adminpass)
        #export  FABRIC_CA_CLIENT_HOME=$ORG_ADMIN_HOME
        #logr "Revoking the user '$USER_NAME' of the organization '$ORG' with Fabric CA Client home directory set to $FABRIC_CA_CLIENT_HOME and generating CRL ..."
        #export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
        #fabric-ca-client revoke -d --revoke.name $USER_NAME --gencrl
        command = "fabric-ca-client revoke -d --revoke.name {0} --gencrl --tls.certfiles /var/hyperledger/configs/{3}/{2}/{1}/ca/ca.{1}-cert.pem".format(user, org, "peerOrganizations", context.projectName)
        output = context.composition.docker_exec([command], [component], env=updated_env)
        print("Revoke output: {}".format(output))

    def generateCRL(self, context, component, org, admin='Admin', adminpass='adminpw'):
        updated_env = config_util.updateEnviron(context)
        updated_env['FABRIC_CA_CLIENT_HOME'] = "/var/hyperledger/users/Admin@{}/msp/crls/crl.pem".format(org)
        # Generates a CRL that contains serial numbers of all revoked enrollment certificates.
        # The generated CRL is placed in the crls folder of the admin's MSP
        self.enrollCAadmin(context, component, admin, adminpass)
        #export FABRIC_CA_CLIENT_HOME=$ORG_ADMIN_HOME
        #logr "Generating CRL for the organization '$ORG' with Fabric CA Client home directory set to $FABRIC_CA_CLIENT_HOME ..."
        #export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
        #fabric-ca-client gencrl -d
        command = "fabric-ca-client gencrl -d --tls.certfiles /var/hyperledger/configs/{2}/{1}/{0}/ca/ca.{0}-cert.pem".format(org, "peerOrganizations", context.projectName)
        output = context.composition.docker_exec([command], [component], env=updated_env)
        print("CRL output: {}".format(output))


    def wait_for_deploy_completion(self, context, chaincode_container, timeout):
        containers = subprocess.check_output(["docker ps -a"], shell=True)
        try:
            with common_util.Timeout(timeout):
                while chaincode_container not in containers:
                    containers = subprocess.check_output(["docker ps -a"], shell=True)
                    time.sleep(1)
        finally:
            assert chaincode_container in containers, "The expected chaincode container {0} is not running\n{1}".format(chaincode_container, containers)

        # Allow time for chaincode initialization to complete
        time.sleep(10)

    def retry(self, context, output, peer, setup, command):
        count = 0
        while count < 3:
            count += 1
            if "been successfully instantiated and try again" in output[peer]:
                time.sleep(5)
                print("Received: {0}, Trying again({1})...".format(output[peer], count))
                output = context.composition.docker_exec(setup+command, [peer])
        return output
