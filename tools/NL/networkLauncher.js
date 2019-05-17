const exec = require('child_process').execSync;
const fs = require('fs');
const path = require('path');
const winston = require('winston');
const yaml = require('js-yaml')
let YAML = require('json2yaml')
    , ymlText
    ;
/*const logger = new (winston.Logger)({
    transports: [
        new winston.transports.Console({
            level: 'debug',
            handleExceptions: true,
            prettyPrint: true,
            colorize: true
        })
    ],
    exitOnError: false
});*/
let argv = require('yargs')
    .options({
        mode: {
            demand: false,
            description: 'Mode to be used and supported options are up, down, restart, addorg, addpeer',
            alias: 'm',
            default: 'up',
            type: 'string'
        },
        input: {
            demand: true,
            description: 'Network spec input file path',
            alias: 'i',
            type: 'string'
        },
        kubeconfig: {
            demand: false,
            description: 'Kube config file path',
            alias: 'k',
            type: 'string'
        }
    })
    .help()
    .argv;

let networkSpec = yaml.safeLoad(fs.readFileSync(argv.input, 'utf8'));
async function networkLauncher(argv) {
    try {
        if (argv.mode == "up") {
            await genCrypto(networkSpec);
            await genConfigtx(networkSpec);
            await genNetwork(networkSpec);
            await genConnProfile(networkSpec);
        } else if (argv.mode == "down") {
            //TODO
        } else if (argv.mode == "restart") {
            //TODO
        } else if (argv.mode == "addpeer") {
            //TODO
        }
    } catch (err) {
        //TODO
    }
}

async function genCrypto(networkSpec) {
    try {
        let cryptoConfig = {}
        let ordSpecs = []
        let peerSpecs = []
        let OrdererOrgs = []
        let PeerOrgs = []

        for (var i = 0; i < networkSpec.orderer_organizations.length; i++) {
            ordSpecs = []
            for (var j = 0; j < networkSpec.orderer_organizations[i].num_orderers; j++) {
                ordSpecs.push({
                    "Hostname": "orderer" + j + "-" + networkSpec.orderer_organizations[i].name
                })
            }
            OrdererOrgs.push({
                "Name": networkSpec.orderer_organizations[i].name,
                "Domain": networkSpec.orderer_organizations[i].name,
                "EnableNodeOUs": true,
                "Specs": ordSpecs
            })
        }

        for (var k = 0; k < networkSpec.peer_organizations.length; k++) {
            peerSpecs = []
            for (var l = 0; l < networkSpec.peer_organizations[k].num_peers; l++) {
                peerSpecs.push({
                    "Hostname": "peer" + l + "-" + networkSpec.peer_organizations[k].name
                })
            }
            PeerOrgs.push({
                "Name": networkSpec.peer_organizations[k].name,
                "Domain": networkSpec.peer_organizations[k].name,
                "EnableNodeOUs": true,
                "Specs": peerSpecs
            })
        }

        cryptoConfig = {
            "OrdererOrgs": OrdererOrgs,
            "PeerOrgs": PeerOrgs
        }

        ymlText = YAML.stringify(cryptoConfig);
        fs.writeFileSync('./crypto-config.yaml', ymlText)
        await exec('cryptogen generate --config=./crypto-config.yaml --output=' + networkSpec.certs_location + '/crypto-config')
    } catch (err) {
        //TODO
    }
}

async function genConfigtx(networkSpec) {

    let Organizations = []
    let ordererOrganizations = []
    let peerOrganizations = []
    let OrdererAddresses = []
    let Consenters = []
    try {
        for (let i = 0; i < networkSpec.orderer_organizations.length; i++) {
            let orderer_organization = networkSpec.orderer_organizations[i]
            for (let j = 0; j < orderer_organization.num_orderers; j++) {
                i = i > 0 ? i : ""
                OrdererAddresses.push("orderer" + j + "-" + orderer_organization.name + ":7050")
                if (networkSpec.orderer.orderertype == "etcdraft") {
                    Consenters.push({
                        "Host": "orderer" + j + "-" + orderer_organization.name,
                        "Port": 7050,
                        "ClientTLSCert": networkSpec.certs_location + "crypto-config/ordererOrganizations/" + orderer_organization.name + "/orderers/orderer" + j + "-" + orderer_organization.name + "." + orderer_organization.name + "/tls/server.crt",
                        "ServerTLSCert": networkSpec.certs_location + "crypto-config/ordererOrganizations/" + orderer_organization.name + "/orderers/orderer" + j + "-" + orderer_organization.name + "." + orderer_organization.name + "/tls/server.crt",
                    })
                }
            }
            ordererOrganizations.push(addOrganizationsForConfigtx(orderer_organization, "orderer", networkSpec.certs_location))
        }
        for (let i = 0; i < networkSpec.peer_organizations.length; i++) {
            let peerer_organization = networkSpec.peer_organizations[i]
            peerOrganizations.push(addOrganizationsForConfigtx(peerer_organization, "peer", networkSpec.certs_location))
        }
        Organizations = ordererOrganizations.concat(peerOrganizations)
        let capabilities = {
            "Global": {
                "V1_3": true
            },
            "Orderer": {
                "V1_1": true
            },
            "Application": {
                "V1_3": true
            }
        }

        let Orderer = {
            "OrdererType": networkSpec.orderer.orderertype,
            "Addresses": OrdererAddresses,
            "BatchTimeout": networkSpec.orderer.batchtimeout,
            "BatchSize": {
                "MaxMessageCount": networkSpec.orderer.batchsize.maxmessagecount,
                "AbsoluteMaxBytes": networkSpec.orderer.batchsize.absolutemaxbytes,
                "PreferredMaxBytes": networkSpec.orderer.batchsize.preferredmaxbytes
            },
            "Organizations": ordererOrganizations,
            "Policies": {
                "Readers": {
                    "Type": "ImplicitMeta",
                    "Rule": "ANY Readers"
                },
                "Writers": {
                    "Type": "ImplicitMeta",
                    "Rule": "ANY Writers"
                },
                "Admins": {
                    "Type": "ImplicitMeta",
                    "Rule": "ANY Admins"
                },
                "BlockValidation": {
                    "Type": "ImplicitMeta",
                    "Rule": "ANY Writers"
                }
            },
            "Capabilities": {
                "V1_1": true
            }
        }
        let EtcdRaft = {
            "Consenters": Consenters,
            "Options": {
                "TickInterval": networkSpec.orderer.etcdraft_options.TickInterval,
                "ElectionTick": networkSpec.orderer.etcdraft_options.ElectionTick,
                "HeartbeatTick": networkSpec.orderer.etcdraft_options.HeartbeatTick,
                "MaxInflightBlocks": networkSpec.orderer.etcdraft_options.MaxInflightBlocks,
                "SnapshotIntervalSize": networkSpec.orderer.etcdraft_options.SnapshotIntervalSize
            }
        }
        if (networkSpec.orderer.orderertype == "etcdraft") {
            Orderer["EtcdRaft"] = EtcdRaft
        }

        let Application = {
            "Organizations": peerOrganizations,
            "Policies": {
                "Readers": {
                    "Type": "ImplicitMeta",
                    "Rule": "ANY Readers"
                },
                "Writers": {
                    "Type": "ImplicitMeta",
                    "Rule": "ANY Writers"
                },
                "Admins": {
                    "Type": "ImplicitMeta",
                    "Rule": "ANY Admins"
                }
            },
            "Capabilities": {
                "V1_3": true
            }
        }

        let Channel = {
            "Policies": {
                "Readers": {
                    "Type": "ImplicitMeta",
                    "Rule": "ANY Readers"
                },
                "Writers": {
                    "Type": "ImplicitMeta",
                    "Rule": "ANY Writers"
                },
                "Admins": {
                    "Type": "ImplicitMeta",
                    "Rule": "ANY Admins"
                }
            },
            "Capabilities": {
                "V1_3": true
            }
        }

        let Profiles = {
            "testorgschannel": {
                "Policies": Channel["Policies"],
                "Capabilities": Channel["Capabilities"],
                "Consortium": "FabricConsortium",
                "Application": {
                    "Organizations": peerOrganizations,
                    "Policies": Channel["Policies"],
                    "Capabilities": Channel["Capabilities"]
                },
                "Orderer": Orderer
            },
            "testOrgsOrdererGenesis": {
                "Policies": Channel["Policies"],
                "Capabilities": Channel["Capabilities"],
                "Orderer": Orderer,
                "Consortiums": {
                    "FabricConsortium": {
                        "Organizations": peerOrganizations
                    }
                }
            }
        }

        const configtxJson = {
            "Organizations": Organizations,
            "Capabilities": capabilities,
            "Orderer": Orderer,
            "Application": Application,
            "Channel": Channel,
            "Profiles": Profiles
        }
        ymlText = YAML.stringify(configtxJson);
        fs.writeFileSync('./configtx.yaml', ymlText)

        await exec('configtxgen -profile testOrgsOrdererGenesis -channelID ordersystemchannel -outputBlock ' + networkSpec.certs_location + 'crypto-config/ordererOrganizations/genesis.block')
        for (let i = 0; i < networkSpec.num_channels; i++) {
            await exec('configtxgen -profile testorgschannel -channelCreateTxBaseProfile testOrgsOrdererGenesis -channelID testorgschannel'+i+' -outputCreateChannelTx ./testorgschannel1.tx')
        }
    } catch (err) {
        //TODO
    }
}

async function genNetwork(networkSpec) {
    try {
        //TODO
    } catch (err) {
        //TODO
    }
}

async function genConnProf(networkSpec) {
    try {
        //TODO
    } catch (err) {
        //TODO
    }
}

function addOrganizationsForConfigtx(organization, type, certs_location) {
    let peerPolicies = {
        "Readers": {
            "Type": "Signature",
            "Rule": "OR('" + organization.name + ".admin', '" + organization.name + ".peer')"
        },
        "Writers": {
            "Type": "Signature",
            "Rule": "OR('" + organization.name + ".admin', '" + organization.name + ".client')"
        },
        "Admins": {
            "Type": "Signature",
            "Rule": "OR('" + organization.name + ".admin')"
        }
    }
    let ordererPolicies = {
        "Readers": {
            "Type": "Signature",
            "Rule": "OR('" + organization.name + ".member')"
        },
        "Writers": {
            "Type": "Signature",
            "Rule": "OR('" + organization.name + ".member')"
        },
        "Admins": {
            "Type": "Signature",
            "Rule": "OR('" + organization.name + ".admin')"
        }
    }
    let Policies = type == "peer" ? peerPolicies : ordererPolicies
    let organizationData = {
        "Name": organization.name,
        "ID": organization.name,
        "MSPDir": certs_location + "crypto-config/" + type + "Organizations/" + organization.name + "/msp",
        "Policies": Policies
    }
    return organizationData
}

networkLauncher(argv);