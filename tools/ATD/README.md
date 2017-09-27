# Ansible Test Driver (ATD) for Hyperledger Fabric-test

Ansible Test Driver is an ansible project which can run tools like PTE and OTE,
which can be found in the fabric-test repository, to test a deployed Hyperledger Fabric network.

ATD can do the following to drive PTE:

 - Builds docker image for PTE and launches PTE in a separate container
 - Drives PTE tests from inside the container
 - Create channels, join peers to channels, install chaincodes on the peers, instantiate the chaincodes, and send
   invokes and queries from PTE container

## Prerequisites

- [Ubuntu 16.04 machines] (https://cloud-images.ubuntu.com/releases/16.04/)
- Install cloud platform dependent packages such as OpenStack shade or AWS boto
- [Install Ansible 2.3.0.0 or above](http://docs.ansible.com/ansible/intro_installation.html)
- Hyperledger Fabric Network - Before using ATD, launch a Hyperledger Fabric Network
using [Cello - Hyperledger Fabric Deployment](https://github.com/hyperledger/cello/tree/master/src/agent/ansible)

## Using ATD
 - Once the network is available, use the ATD from ansible controller to drive the tests
 - Clone the [fabric-test repository](https://gerrit.hyperledger.org/r/fabric-test) onto the ansible controller
```
  cd .../path/to/fabric-test
  git submodule update --init --recursive    # initialize the git submodules
  cd .../path/to/cello/src/agent/ansible/    # and launch the network; then:
  cp run/runhosts .../path/to/fabric-test/tools/ATD/
```
Next, copy the environment variable file used for launching the network from the directory cello/src/agent/ansible/vars/. For example, if the network is launched by using the following command `ansible-playbook -i run/runhosts -e "mode=apply env=bc1st deploy_type=compose" setupfabric.yml`, then `bc1st` is the environment variable file. Your command might look something like this:
```
  cp .../path/to/cello/src/agent/ansible/vars/bc1st.yml .../path/to/fabric-test/tools/ATD/vars/
```
    
Now, run the following command to launch the PTE in a container
```
  cd .../path/to/fabric-test/tools/ATD/
  ansible-playbook -i run/runhosts --extra-vars "host=osfabric004 TESTCASE=3390" -e "mode=apply env=bc1st tool_type=pte" ptesetup.yml
```

In the above command,
 - `--extra-vars "var=<value>" to pass in a variable to the playbook
   host=<name of the machine> is used to pass the name of the host where PTE has to run
   TESTCASE=<Testcase Number>"` is used to run a specific testcase that is defined in the PTE/CITest directory
 - `env=<value>`to pass the environment variable file 
    For example, in the above example, env=bc1st refers to bc1st.yml environment file
 - `mode=<apply|destroy>` refers to set the mode for PTE in a container.
        - `mode=apply` launch the PTE container,
        - `mode=destroy` remove the PTE container and PTE image and network artifacts of the test environment
 - `tool_type=<type of tool>` type of tool to drive
        - `tool_type=pte` to run the PTE
