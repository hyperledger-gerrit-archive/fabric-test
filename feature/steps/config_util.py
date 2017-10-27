#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#


import subprocess
import os
import sys
from shutil import copyfile
import uuid

ORDERER_TYPES = ["solo",
                 "kafka",
                 "solo-msp"]

PROFILE_TYPES = {"solo": "SampleInsecureSolo",
                 "kafka": "SampleInsecureKafka",
                 "solo-msp": "SampleSingleMSPSolo"}

CHANNEL_PROFILE = "SysTestChannel"

ORDERER_STR = '''
OrdererOrgs:
  - Name: ExampleCom
    Domain: example.com
    Specs: '''

ORDERER_HOST = '''
      - Hostname: orderer{count} '''

PEER_ORG_STR = '''
  - Name: {name}
    Domain: {domain}
    EnableNodeOUs: {ouEnable}
    Template:
      Count: {numPeers}
    Users:
      Count: {numUsers}
'''

def updateEnviron(context):
    updated_env = os.environ.copy()
    if hasattr(context, "composition"):
        updated_env.update(context.composition.getEnv())
    return updated_env

def makeProjectConfigDir(context, returnContext=False):
    # Save all the files to a specific directory for the test
    if not hasattr(context, "projectName") and not hasattr(context, "composition"):
        projectName = str(uuid.uuid1()).replace('-','')
        context.projectName = projectName
    elif hasattr(context, "composition"):
        projectName = context.composition.projectName
        context.projectName = projectName
    else:
        projectName = context.projectName

    testConfigs = "configs/%s" % projectName
    if not os.path.isdir(testConfigs):
        os.mkdir(testConfigs)
    if returnContext:
        return testConfigs, context
    return testConfigs

def buildCryptoFile(context, numOrgs, numPeers, numOrderers, numUsers, orgName=None, ouEnable=False):
    testConfigs = makeProjectConfigDir(context)

    # Orderer Stanza
    ordererHostStr = ""
    for count in range(int(numOrderers)):
        ordererHostStr += ORDERER_HOST.format(count=count)
    ordererStr = ORDERER_STR + ordererHostStr

    # Peer Stanza
    peerStanzas = ""
    for count in range(int(numOrgs)):
        name = "Org{0}ExampleCom".format(count+1)
        domain = "org{0}.example.com".format(count+1)
        if orgName is not None:
            name = orgName.title().replace('.', '')
            domain = orgName
        peerStanzas += PEER_ORG_STR.format(name=name, domain=domain, numPeers=numPeers, numUsers=numUsers, ouEnable=ouEnable)
    peerStr = "PeerOrgs:" + peerStanzas

    cryptoStr = ordererStr + "\n\n" + peerStr
    with open("{0}/crypto.yaml".format(testConfigs), "w") as fd:
        fd.write(cryptoStr)

def setCAConfig(context):
    testConfigs, context = makeProjectConfigDir(context, returnContext=True)
    orgDirs = getOrgs(context)
    for orgDir in orgDirs:
        #os.mkdir("{0}/{1}".format(testConfigs, orgDir))
        with open("configs/fabric-ca-server-config.yaml", "r") as fd:
            config_template = fd.read()
            config = config_template.format(orgName=orgDir)
        with open("{0}/{1}/fabric-ca-server-config.yaml".format(testConfigs, orgDir), "w") as fd:
            fd.write(config)
    return context

def setupConfigsForCA(context, channelID):
    testConfigs = makeProjectConfigDir(context)
    print("testConfigs: {0}".format(testConfigs))

    configFile = "configtx_fca.yaml"
    if os.path.isfile("configs/%s.yaml" % channelID):
        configFile = "%s.yaml" % channelID

    copyfile("configs/%s" % configFile, "%s/configtx.yaml" % testConfigs)

    #orgDirs = [d for d in os.listdir("./{0}/".format(testConfigs)) if (("example.com" in d) and (os.path.isdir("./{0}/{1}".format(testConfigs, d))))]
    orgDirs = getOrgs(context)
    print("Org Dirs: {}".format(orgDirs))

    for orgDir in orgDirs:
        copyfile("{0}/configtx.yaml".format(testConfigs),
                 "{0}/{1}/msp/config.yaml".format(testConfigs, orgDir))

        os.mkdir("{0}/{1}/msp/cacerts".format(testConfigs, orgDir))
        os.mkdir("{0}/{1}/msp/admincerts".format(testConfigs, orgDir))
        copyfile("{0}/ca.{1}-cert.pem".format(testConfigs, orgDir),
                 "{0}/{1}/msp/cacerts/ca.{1}-cert.pem".format(testConfigs, orgDir))
        copyfile("{0}/ca.{1}-cert.pem".format(testConfigs, orgDir),
                 "{0}/{1}/msp/admincerts/ca.{1}-cert.pem".format(testConfigs, orgDir))

def certificateSetupForCA(context):
    testConfigs = makeProjectConfigDir(context)
    orgDirs = [d for d in os.listdir("./{0}/".format(testConfigs)) if (("example.com" in d) and (os.path.isdir("./{0}/{1}".format(testConfigs, d))))]
    for orgDir in orgDirs:
        #if os.path.isdir("{0}/{1}/orderer0.example.com/msp/signcerts".format(testConfigs, orgDir)):
        if os.path.isdir("{0}/{1}/orderer0.example.com".format(testConfigs, orgDir)):
            copyfile("{0}/configtx.yaml".format(testConfigs),
                     "{0}/{1}/orderer0.example.com/msp/config.yaml".format(testConfigs, orgDir))
            copyfile("{0}/{1}/orderer0.example.com/msp/signcerts/cert.pem".format(testConfigs, orgDir),
                     "{0}/{1}/msp/admincerts/cert.pem".format(testConfigs, orgDir))
            copyfile("{0}/ca.{1}-cert.pem".format(testConfigs, orgDir),
                     "{0}/{1}/msp/cacerts/ca.{1}-cert.pem".format(testConfigs, orgDir))

def setupConfigs(context, channelID):
    testConfigs = makeProjectConfigDir(context)
    print("testConfigs: {0}".format(testConfigs))

    configFile = "configtx.yaml"
    if os.path.isfile("configs/%s.yaml" % channelID):
        configFile = "%s.yaml" % channelID

    copyfile("configs/%s" % configFile, "%s/configtx.yaml" % testConfigs)

    # Copy config to orderer org structures
    for orgDir in os.listdir("./{0}/ordererOrganizations".format(testConfigs)):
        copyfile("{0}/configtx.yaml".format(testConfigs),
                 "{0}/ordererOrganizations/{1}/msp/config.yaml".format(testConfigs,
                                                                       orgDir))
    # Copy config to peer org structures
    for orgDir in os.listdir("./{0}/peerOrganizations".format(testConfigs)):
        copyfile("{0}/configtx.yaml".format(testConfigs),
                 "{0}/peerOrganizations/{1}/msp/config.yaml".format(testConfigs,
                                                                    orgDir))
        copyfile("{0}/configtx.yaml".format(testConfigs),
                 "{0}/peerOrganizations/{1}/users/Admin@{1}/msp/config.yaml".format(testConfigs,
                                                                                    orgDir))

def inspectOrdererConfig(context, filename):
    testConfigs = makeProjectConfigDir(context)
    updated_env = updateEnviron(context)
    try:
        command = ["configtxgen", "-inspectBlock", filename]
        return subprocess.check_output(command, cwd=testConfigs, env=updated_env)
    except:
        print("Unable to inspect orderer config data: {0}".format(sys.exc_info()[1]))

def inspectChannelConfig(context, filename):
    testConfigs = makeProjectConfigDir(context)
    updated_env = updateEnviron(context)
    try:
        command = ["configtxgen", "-inspectChannelCreateTx", filename]
        return subprocess.check_output(command, cwd=testConfigs, env=updated_env)
    except:
        print("Unable to inspect channel config data: {0}".format(sys.exc_info()[1]))

def generateConfigForCA(context, channelID, profile, ordererProfile, block="orderer.block"):
    setupConfigsForCA(context, channelID)
    generateOrdererConfig(context, channelID, ordererProfile, block)
    generateChannelConfig(channelID, profile, context)
    generateChannelAnchorConfig(channelID, profile, context)
    certificateSetupForCA(context)

def generateConfig(context, channelID, profile, ordererProfile, block="orderer.block"):
    setupConfigs(context, channelID)
    generateOrdererConfig(context, channelID, ordererProfile, block)
    generateChannelConfig(channelID, profile, context)
    generateChannelAnchorConfig(channelID, profile, context)

def generateOrdererConfig(context, channelID, ordererProfile, block):
    testConfigs = makeProjectConfigDir(context)
    updated_env = updateEnviron(context)
    try:
        command = ["configtxgen", "-profile", ordererProfile,
                   "-outputBlock", block,
                   "-channelID", channelID]
        subprocess.check_call(command, cwd=testConfigs, env=updated_env)
    except:
        print("Unable to generate orderer config data: {0}".format(sys.exc_info()[1]))

def generateChannelConfig(channelID, profile, context):
    testConfigs = makeProjectConfigDir(context)
    updated_env = updateEnviron(context)
    try:
        command = ["configtxgen", "-profile", profile,
                   "-outputCreateChannelTx", "%s.tx" % channelID,
                   "-channelID", channelID]
        subprocess.check_call(command, cwd=testConfigs, env=updated_env)
    except:
        print("Unable to generate channel config data: {0}".format(sys.exc_info()[1]))

def getOrgs(context):
    testConfigs = makeProjectConfigDir(context)
    if os.path.exists("./{0}/peerOrganizations".format(testConfigs)):
        orgs = os.listdir("./{0}/peerOrganizations".format(testConfigs)) + os.listdir("./{0}/ordererOrganizations".format(testConfigs))
    else:
        orgs = [d for d in os.listdir("./{0}/".format(testConfigs)) if (("example.com" in d) and (os.path.isdir("./{0}/{1}".format(testConfigs, d))))]

    return orgs

def generateChannelAnchorConfig(channelID, profile, context):
    testConfigs = makeProjectConfigDir(context)
    updated_env = updateEnviron(context)
    orglist = getOrgs(context)
    if 'example.com' in orglist:
        orglist.remove('example.com')
    for org in orglist:
        try:
            command = ["configtxgen", "-profile", profile,
                       "-outputAnchorPeersUpdate", "{0}{1}Anchor.tx".format(org, channelID),
                       "-channelID", channelID,
                       "-asOrg", org.title().replace('.', '')]
            subprocess.check_call(command, cwd=testConfigs, env=updated_env)
        except:
            print("Unable to generate channel anchor config data: {0}".format(sys.exc_info()[1]))

def generateCrypto(context, cryptoLoc="./configs/crypto.yaml"):
    testConfigs = makeProjectConfigDir(context)
    updated_env = updateEnviron(context)
    try:
        subprocess.check_call(["cryptogen", "generate",
                               '--output={0}'.format(testConfigs),
                               '--config={0}'.format(cryptoLoc)],
                              env=updated_env)
    except:
        print("Unable to generate crypto material: {0}".format(sys.exc_info()[1]))

def traverse_orderer(projectname, numOrderers, tlsExist):
    # orderer stanza
    opath = 'configs/' +projectname+ '/ordererOrganizations/example.com/'
    capath = opath + 'ca/'
    caCertificates(capath)

    msppath = opath + 'msp/'
    rolebasedCertificate(msppath)

    for count in range(int(numOrderers)):
        ordererpath = opath + 'orderers/' + "orderer" +str(count)+".example.com/"
        mspandtlsCheck(ordererpath, tlsExist)

    userpath = opath + 'users/Admin@example.com/'
    mspandtlsCheck(userpath, tlsExist)

def traverse_peer(projectname, numOrgs, numPeers, numUsers, tlsExist, orgName=None):
    # Peer stanza
    pppath = 'configs/' +projectname+ '/peerOrganizations/'
    for orgNum in range(int(numOrgs)):
        if orgName is None:
            orgName = "org" + str(orgNum) + ".example.com"
        for peerNum in range(int(numPeers)):
            orgpath = orgName + "/"
            ppath = pppath + orgpath
            peerpath = ppath +"peers/"+"peer"+str(peerNum)+ "."+ orgpath

            mspandtlsCheck(peerpath, tlsExist)

            capath = ppath + 'ca/'
            caCertificates(capath)

            msppath = ppath + 'msp/'
            rolebasedCertificate(msppath)
            keystoreCheck(msppath)

            userAdminpath = ppath +"users/"+"Admin@"+orgpath
            mspandtlsCheck(userAdminpath, tlsExist)

            for count in range(int(numUsers)):
                userpath = ppath + "users/"+"User"+str(count)+"@"+orgpath
                mspandtlsCheck(userpath, tlsExist)

def generateCryptoDir(context, numOrgs, numPeers, numOrderers, numUsers, tlsExist=True, orgName=None):
    projectname = context.projectName
    traverse_peer(projectname, numOrgs, numPeers, numUsers, tlsExist, orgName)
    traverse_orderer(projectname, numOrderers, tlsExist)

def mspandtlsCheck(path, tlsExist):
    msppath = path + 'msp/'
    rolebasedCertificate(msppath)
    keystoreCheck(msppath)

    if not tlsExist:
       tlspath = path + 'tls/'
       tlsCertificates(tlspath)

def fileExistWithExtension(path, message, fileExt=''):
    for root, dirnames, filenames in os.walk(path):
        assert len(filenames) > 0, "{0}: len: {1}".format(message, len(filenames))
        fileCount = [filename.endswith(fileExt) for filename in filenames]
        assert fileCount.count(True) >= 1

def rolebasedCertificate(path):
    adminpath = path + "admincerts/"
    fileExistWithExtension(adminpath, "There is not .pem cert in {0}.".format(adminpath), '.pem')

    capath = path + "cacerts/"
    fileExistWithExtension(capath, "There is not .pem cert in {0}.".format(capath), '.pem')

    signcertspath = path + "signcerts/"
    fileExistWithExtension(signcertspath, "There is not .pem cert in {0}.".format(signcertspath), '.pem')

    tlscertspath = path + "tlscerts/"
    fileExistWithExtension(tlscertspath, "There is not .pem cert in {0}.".format(tlscertspath), '.pem')

def caCertificates(path):
    # There are no ca directories containing pem files
    fileExistWithExtension(path, "There are missing files in {0}.".format(path), '_sk')
    fileExistWithExtension(path, "There is not .pem cert in {0}.".format(path), '.pem')

def tlsCertificates(path):
    for root, dirnames, filenames in os.walk(path):
        assert len(filenames) == 3, "There are missing certificates in the {0} dir".format(path)
        for filename in filenames:
            assert filename.endswith(('.crt','.key')), "The files in the {0} directory are incorrect".format(path)

def keystoreCheck(path):
    keystorepath = path + "keystore/"
    fileExistWithExtension(keystorepath, "There are missing files in {0}.".format(keystorepath), '')

#def enrollUsersFabricCA(context):
#    for user in context.users.keys():
#        org = context.users[user]['organization']
#        passwd = context.users[user]['password']
#        role = context.users[user]['role']
#        fca = 'ca.{}'.format(org)
#        peer = 'peer0.{}.example.com'.format(org)
#        #output = context.composition.docker_exec(["fabric-ca-client enroll -d -u https://{0}:{1}@{2}:7054".format(user, passwd, fca)], [peer])
#        output = context.composition.docker_exec(["fabric-ca-client enroll -d -u $${ENROLLMENT_URL} --enrollment.profile tls --id.name {0} --id.secret {1} --id.affiliation {2}".format(user, passwd, org)], [peer])
#        print("Output: {}".format(output))

def getCaCert(context, node, fca):
    #fabric-ca-client getcacert -d -u https://$CA_HOST:7054 -M $ORG_MSP_DIR
    if node.startswith("orderer"):
        mspdir = context.composition.getEnvFromContainer(node, 'ORDERER_GENERAL_LOCALMSPDIR')
    elif node.startswith("peer"):
        mspdir = context.composition.getEnvFromContainer(node, 'CORE_PEER_MSPCONFIGPATH')
    output = context.composition.docker_exec(["fabric-ca-client getcacert -d -u https://{0}:7054 -M {1}".format(fca, mspdir)], [node])
    print("Output getcacert: {}".format(output))

def getUserPass(context, container_name):
    for container in context.composition.containerDataList:
        if container_name in container.containerName:
            userpass = container.getEnv('BOOTSTRAP_USER_PASS')
            break

#def registerIdentities(context, nodes):
#    for node in nodes:
#        # fabric-ca-client enroll -d -u https://$CA_ADMIN_USER_PASS@$CA_HOST:7054
#        # fabric-ca-client register -d --id.name $ORDERER_NAME --id.secret $ORDERER_PASS
#        url = context.composition.getEnvFromContainer(node, 'ENROLLMENT_URL')
#        output = context.composition.docker_exec(["fabric-ca-client enroll -d -u {}".format(url)], [node])
#        print("Output Enroll: {}".format(output))
#        userpass = context.composition.getEnvFromContainer(node, 'BOOTSTRAP_USER_PASS').split(":")
#        output = context.composition.docker_exec(["fabric-ca-client register -d --id.name {0} --id.secret {1}".format(userpass[0], userpass[1])], [node])
#        print("Output register: {}".format(output))

def registerUsers(context):
    for user in context.users.keys():
        #fabric-ca-client register -d --id.name $ADMIN_NAME --id.secret $ADMIN_PASS
        org = context.users[user]['organization']
        passwd = context.users[user]['password']
        role = context.users[user]['role']
        fca = 'ca.{}'.format(org)
        #peer = 'peer0.{}.example.com'.format(org)
        output = context.composition.docker_exec(["fabric-ca-client register -d --id.name {0} --id.secret {1}".format(user, passwd)], [fca])
        print("user register: {}".format(output))

def registerWithABAC(context, user):
    '''
    ABAC == Attribute Based Access Control
    '''
    org = context.users[user]['organization']
    passwd = context.users[user]['password']
    role = context.users[user]['role']
    fca = 'ca.{}'.format(org)
    #peer = 'peer0.{}.example.com'.format(org)
    attr = []
    for abac in context.abac.keys():
        if context.abac[abac] == 'required':
            attr.append("{0}=true:ecert".format(abac))
        else:
            attr.append("{0}=true".format(abac))
    #fabric-ca-client register -d --id.name $ADMIN_NAME --id.secret $ADMIN_PASS --id.attrs "hf.admin=true:ecert"
    attr_reqs = ",".join(attr)
    output = context.composition.docker_exec(['fabric-ca-client register -d --id.name {0} --id.secret {1} --id.attrs "{2}"'.format(user, passwd, attr_reqs)], [fca])
    print("ABAC register: {}".format(output))

def configUpdate(context, config_update, group, channel):
    updated_env = updateEnviron(context)
    testConfigs = "./configs/{0}".format(context.projectName)
    inputFile = "{0}.block".format(channel)

    # configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json
    configStr = subprocess.check_output(["configtxlator", "proto_decode", "--input", inputFile, "--type", "common.Block"], cwd=testConfigs , env=updated_env)
    config = json.loads(configStr)

    #print("config: {}".format(config))

    with open("{0}/config.json".format(testConfigs), "w") as fd:
        fd.write(json.dumps(config["data"]["data"][0]["payload"]["data"]["config"]))

    # configtxlator proto_encode --input config.json --type common.Config --output config.pb
    configStr = subprocess.check_output(["configtxlator", "proto_encode", "--input", "config.json", "--type", "common.Config", "--output", "config.pb"],
                                        cwd=testConfigs,
                                        env=updated_env)
    #config = json.loads(configStr)
    print("Keys: {}".format(config.keys()))
    print("Keys: {}".format(config['data'].keys()))
    print("Keys (data): {}".format(config['data']['data'][0]["payload"]["data"].keys()))
    print("Keys (config): {}".format(config['data']['data'][0]["payload"]["data"]['config'].keys()))
    print("Keys (last_update): {}".format(config['data']['data'][0]["payload"]["data"]['last_update']))
    print("Keys (channel_group): {}".format(config['data']['data'][0]["payload"]["data"]['config']['channel_group'].keys()))

    # jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org3MSP":.[1]}}}}}' config.json ./channel-artifacts/org3.json > modified_config.json
    # config_update = {"Org3ExampleCom": <data>}
    config["data"]["data"][0]["payload"]["data"]["config"]["channel_group"]["groups"][group]["groups"] = config_update


    with open("{0}/modified_config.json".format(testConfigs), "w") as fd:
        fd.write(json.dumps(config["data"]["data"][0]["payload"]["data"]["config"]))

    print("Modified config: {}".format(config))

    # configtxlator proto_encode --input config.json --type common.Config --output config.pb
    configStr = subprocess.check_output(["configtxlator", "proto_encode", "--input", "config.json", "--type", "common.Config", "--output", "config.pb"],
                                        cwd=testConfigs,
                                        env=updated_env)

    # configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
    configStr = subprocess.check_output(["configtxlator", "proto_encode", "--input", "modified_config.json", "--type", "common.Config", "--output", "modified_config.pb"],
                                        cwd=testConfigs,
                                        env=updated_env)

    #config = json.loads(configStr)
    print("Output: {}".format(configStr))

    # configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output update.pb
    configStr = subprocess.check_output(["configtxlator", "compute_update", "--channel_id", channel, "--original", inputFile, "--updated", "modified_config.pb", "--output", "update.pb"],
                                        cwd=testConfigs,
                                        env=updated_env)

    # configtxlator proto_decode --input update.pb --type common.ConfigUpdate | jq . > org3_update.json
    configStr = subprocess.check_output(["configtxlator", "proto_decode", "--input", "update.pb", "--type", "common.ConfigUpdate"],
                                        cwd=testConfigs,
                                        env=updated_env)

    config = json.loads(configStr)

    # echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat org3_update.json)'}}}' | jq . > org3_update_in_envelope.json
    updatedconfig = {"payload":
                        {"header":
                             {"channel_header": {"channel_id":"mychannel",
                                                 "type":2}
                             },
                         "data": {"config_update": config }
                        }
                    }

    with open("{0}/update.json".format(testConfigs), "w") as fd:
        fd.write(json.dumps(updatedconfig))

    # configtxlator proto_encode --input org3_update_in_envelope.json --type common.Envelope --output org3_update_in_envelope.pb
    configStr = subprocess.check_output(["configtxlator", "proto_encode", "--input", "update.json", "--type", "common.Envelope", "--output", "update{0}.pb".format(channel)],
                                        cwd=testConfigs,
                                        env=updated_env)

    return "{0}/update{1}.pb".format(testConfigs, channel)

    ## peer channel signconfigtx -f org3_update_in_envelope.pb
    ## peer channel update -f org3_update_in_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050 --tls --cafile $ORDERER_CA
