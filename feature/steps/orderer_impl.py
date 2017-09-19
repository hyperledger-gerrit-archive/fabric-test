#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

from behave import *
import os
import subprocess
import time
import orderer_util
import basic_impl
import compose_util
import common_util


ORDERER_TYPES = ["solo",
                 "kafka",
                 "solo-msp"]

PROFILE_TYPES = {"solo": "SampleInsecureSolo",
                 "kafka": "SampleInsecureKafka",
                 "solo-msp": "SampleSingleMSPSolo"}


@given(u'I test the access to the generated python protobuf files')
def step_impl(context):
    orderer_util._testAccessPBMethods()

@given(u'a bootstrapped orderer network of type {ordererType}')
def step_impl(context, ordererType):
    basic_impl.bootstrapped_impl(context, ordererType)

@given(u'an unbootstrapped network using "{dockerFile}"')
def compose_impl(context, dockerFile):
    pass

@given(u'an orderer connected to the kafka cluster')
def step_impl(context):
    pass

@given(u'the {key} environment variable is {value}')
def step_impl(context, key, value):
    if not hasattr(context, "composition"):
        context.composition = compose_util.Composition(context, startContainers=False)
    changedString = common_util.changeFormat(value)
    context.composition.environ[key] = changedString

@given(u'a certificate from {organization} is added to the kafka orderer network')
def step_impl(context, organization):
    pass

@given(u'a kafka cluster')
def step_impl(context):
    pass

@when(u'a message is broadcasted')
def step_impl(context):
    broadcast_impl(context, 1)

@when(u'{count} unique messages are broadcasted')
def broadcast_impl(context, count):
    pass

@when(u'the topic partition leader is {takeDownType} on {orderer}')
def stop_leader_impl(context, orderer, takeDownType):
    brokers = orderer_util.getKafkaBrokerList(context, orderer)
    kafkas = orderer_util.getKafkaIPs(context, brokers)
    leader = orderer_util.getKafkaPartitionLeader(kafkaBrokers=kafkas)
    topic, isr_list = orderer_util.getKafkaTopic(kafkaBrokers=kafkas)
    print(leader)

    # Save stopped broker
    if not hasattr(context, "stopped_brokers"):
        context.stopped_brokers = []
    context.stopped_brokers.append(leader)
    # Now that we know the kafka leader, stop it
    context.composition.stop([leader])

    #get the remaining brokers from isr_list
    for broker in context.stopped_brokers:
       if broker not in isr_list:
           continue
       else:
           isr_list.remove(broker)
    context.isr_list=isr_list
    context.leader=leader

@when(u'the topic partition leader is {takeDownType}')
def step_impl(context, takeDownType):
    stop_leader_impl(context, "orderer0.example.com", takeDownType)

@when(u'a kafka broker that is not in the ISR set is stopped on {orderer}')
def stop_non_isr_impl(context, orderer):
    brokers = orderer_util.getKafkaBrokerList(context, orderer)
    kafkas = orderer_util.getKafkaIPs(context, brokers)
    kafka = orderer_util.getNonISRKafkaBroker(kafkaBrokers=kafkas)

    if not hasattr(context, "stopped_non_isr"):
        context.stopped_non_isr = []
    context.stopped_non_isr.append(kafka)
    context.composition.stop([kafka])

@when(u'a kafka broker that is not in the ISR set is stopped')
def step_impl(context):
    stop_non_isr_impl(context, "orderer0.example.com")

@when(u'a former topic partition leader is {bringUpType} for {orderer}')
def start_leader_impl(context, orderer, bringUpType):
    # Get the last stopped kafka broker from the stopped broker list
    broker = context.stopped_brokers.pop()
    context.composition.start([broker])

@when(u'a former topic partition leader is {bringUpType}')
def step_impl(context, bringUpType):
    start_leader_impl(context, "orderer0.example.com", bringUpType)

@when(u'a new organization {organization} certificate is added')
def step_impl(context, organization):
    pass

@when(u'authorization for {organization} is removed from the kafka cluster')
def step_impl(context, organization):
    pass

@when(u'authorization for {organization} is added to the kafka cluster')
def step_impl(context, organization):
    pass

@then(u'ensure isr_set is one')
def step_impl(context):
    assert len(context.isr_list)==1, "isr_list has more than expected brokers"
    for kafka in context.isr_list:
        kafka=context.leader

@then(u'the broker is reported as down')
def step_impl(context):
    #for each broker in isr_list check logs
    for kafka in context.isr_list:
        assert is_in_log(kafka, "Shutdown completed (kafka.server.ReplicaFetcherThread)"), "could not verify in the remaining broker logs that broker is down"

@then(u'the broadcasted message is delivered')
def step_impl(context):
    verify_deliver_impl(context, 1, 1)

@then(u'all {count} messages are delivered in {numBlocks} block')
def step_impl(context, count, numBlocks):
    verify_deliver_impl(context, count, numBlocks)

@then(u'all {count} messages are delivered within {timeout} seconds')
def step_impl(context, count, timeout):
    verify_deliver_impl(context, count, None, timeout)

@then(u'all {count} messages are delivered in {numBlocks} within {timeout} seconds')
def verify_deliver_impl(context, count, numBlocks, timeout=60):
    pass

@then(u'I get a successful broadcast response')
def step_impl(context):
    recv_broadcast_impl(context, 1)

@then(u'I get {count} successful broadcast responses')
def recv_broadcast_impl(context, count):
    pass

@then(u'the {organization} cannot connect to the kafka cluster')
def step_impl(context, organization):
    pass

@then(u'the {organization} is able to connect to the kafka cluster')
def step_impl(context, organization):
    pass

@then(u'the zookeeper notifies the orderer of the disconnect')
def step_impl(context):
    pass

@then(u'the orderer functions successfully')
def step_impl(context):
    # Check the logs for certain key info - be sure there are no errors in the logs
    pass

@then(u'the orderer stops sending messages to the cluster')
def step_impl(context):
    pass

@then(u'the {key} environment variable is {value} on node "{node}"')
def step_impl(context, key, value, node):
    assert hasattr(context, "composition"), "There are no containers running for this test"
    changedString = common_util.changeFormat(value)
    container = context.composition.getContainerFromName(node, context.composition.containerDataList)
    containerValue = container.getEnv(key)
    assert containerValue == changedString, "The environment variable on the container was set to {}".format(containerValue)

def is_in_log(container, keyText):
    rc = subprocess.call(
            "docker logs "+container+" 2>&1 | grep "+"\""+keyText+"\"",
            shell=True)
    if rc==0:
        return True
    return False
