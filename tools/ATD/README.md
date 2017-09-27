# Ansible Test Driver (ATD) for Hyperledger Fabric-test

Ansible Test Driver is an ansible driven automated tool which can drive tools like PTE and OTE,
which can be found in the fabric-test repository, to test several components on a deployed Hyperledger Fabric network.

ATD can do the following to drive PTE:

Driving PTE using ATD reduces the effort of modifying the channel configuration files, samplecc-create-chan-TLS.json files
and running the create, join, install, instantiate, invokes and queries separately by doing the following:

 - Auto-generates channel configuration files that are necessary to run PTE by parsing vars/ptevars.yml
 - Auto-generates samplecc-create-chan-TLS.json files that are required to create the channels by parsing vars/ptevars.yml
 - Generates channel configuration transactions using configtxgen and mounts them to PTE docker container
 - Builds docker image for PTE and launches PTE in a separate container
 - Drives PTE tests from inside the container
 - Create channels, join peers to channels, install chaincodes on the peers, instantiate the chaincodes, and send
   invokes and queries from PTE container


## Prerequisites

- [Ubuntu 16.04 machines] (https://cloud-images.ubuntu.com/releases/16.04/)
- [Install Ansible 2.3.0.0 or above](http://docs.ansible.com/ansible/intro_installation.html)
  ```
  sudo apt-get update
  sudo apt-get install python-dev python-pip libssl-dev libffi-dev -y
  sudo pip install --upgrade pip
  sudo pip install six==1.10.0
  sudo pip install ansible==2.3.0.0
  ```
- Hyperledger Fabric Network - Before using ATD, launch a Hyperledger Fabric Network
using [Cello - Hyperledger Fabric Deployment](https://github.com/hyperledger/cello/tree/master/src/agent/ansible)

## Using ATD to drive PTE
 - Once the network is available, use the ATD from ansible controller to drive the tests
 - Clone the [fabric-test repository](https://gerrit.hyperledger.org/r/fabric-test) onto the ansible controller
```
  cd .../path/to/fabric-test
  git submodule update --init --recursive    # initialize the git submodules
  cd .../path/to/cello/src/agent/ansible/    # and launch the network; then:
  cp run/runhosts .../path/to/fabric-test/tools/ATD/
```
Next, copy the environment variable file used for launching the network from the directory cello/src/agent/ansible/vars/. 
For example, if the network is launched by using the following command 
`ansible-playbook -i run/runhosts -e "mode=apply env=bc1st deploy_type=compose" setupfabric.yml`, 
then `bc1st` is the environment variable file. Your command might look something like this:
```
  cp .../path/to/cello/src/agent/ansible/vars/bc1st.yml .../path/to/fabric-test/tools/ATD/vars/
```
Next, edit vars/ptevars.yml with your list of channel number, channel names, organizations that are part of that channel,
and the orderer to which the requests have to be routed based on hyperledger fabric network configuration.

For example, vars/ptevars.yml looks like this
```
pte: {

  # The user to connect to the server
  ssh_user: "ubuntu",
  ptechannels: {
    1: {
      name: "testorgschannel1",
      orgs: ["orga", "orgb"],
      orderer: "orderer0"
    },
    2: {
      name: "testorgschannel2",
      orgs: ["orgc", "orgd"],
      orderer: "orderer1"
    }
  }
}

```

Now, run the following command to launch the PTE in a container
```
  cd .../path/to/fabric-test/tools/ATD/
  ansible-playbook -i run/runhosts --extra-vars "host=osfabric004 chaincode=samplecc testcase=3390" -e "mode=apply env=bc1st tool_type=pte" ptesetup.yml
```

Behind the scenes, it will use templates under `roles/tool_pte/ptesetup/templates/` to generate the chan-config-TLS.json,
samplecc-chan-create-TLS.json, pte-compose.json files depending vars/ptevars.yml

In the above command,
 - `--extra-vars "var=<value>"` to pass in a variable to the playbook
   `host=<name of the machine>` is used to pass the name of the host where PTE has to run
   `testcase=<Testcase Number>` is used to run a specific testcase that is defined in the PTE/CITest directory
   `chaincode=<chaincode name>` is used to specify which chaincode to use. It can be chaincode=samplecc | all | marbles.
 - `env=<value>`to pass the environment variable file
    For example, in the above example, `env=bc1st` refers to bc1st.yml environment file
 - `mode=<apply|destroy>` refers to set the mode for PTE in a container.
        - `mode=apply` launch the PTE container,
        - `mode=destroy` remove the PTE container and PTE image and network artifacts of the test environment
 - `tool_type=<type of tool>` type of tool to drive
        - `tool_type=pte` to run the PTE
