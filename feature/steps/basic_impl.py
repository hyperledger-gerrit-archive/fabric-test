#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

from behave import *
import time
import os
import uuid
import common_util
import compose_util
import config_util
from endorser_util import CLIInterface, ToolInterface, SDKInterface


@given(u'I wait "{seconds}" seconds')
@when(u'I wait "{seconds}" seconds')
@then(u'I wait "{seconds}" seconds')
def step_impl(context, seconds):
    time.sleep(float(seconds))

@given(u'I use the {language} SDK interface')
def step_impl(context, language):
    context.interface = SDKInterface(language)

@given(u'I use the CLI interface')
def step_impl(context):
    context.interface = CLIInterface()

@given(u'I use the tool interface {toolCommand}')
def step_impl(context, toolCommand):
    # The tool command is what is used to generate the network that will be setup for use in the tests
    context.network = toolCommand
    context.interface = ToolInterface(context)

@given(u'I compose "{composeYamlFile}"')
def compose_impl(context, composeYamlFile, projectName=None, startContainers=True):
    if not hasattr(context, "composition"):
       context.composition = compose_util.Composition(context, composeYamlFile,
                                           projectName=projectName,
                                           startContainers=startContainers)
    else:
        context.composition.composeFilesYaml = composeYamlFile
        context.composition.up()
    context.compose_containers = context.composition.collectServiceNames()

def bootstrapped_impl(context, ordererType, database, tlsEnabled=False):
    assert ordererType in config_util.ORDERER_TYPES, "Unknown network type '%s'" % ordererType
    curpath = os.path.realpath('.')

    # Get the correct composition file
    if database == "leveldb":
        context.composeFile = "%s/docker-compose/docker-compose-%s.yml" % (curpath, ordererType)
    else:
        context.composeFile = "%s/docker-compose/docker-compose-%s-%s.yml" % (curpath, ordererType, database)
    assert os.path.exists(context.composeFile), "The docker compose file does not exist: {0}".format(context.composeFile)

    # Should TLS be enabled
    context.tls = tlsEnabled
    common_util.enableTls(context, tlsEnabled)

    # Perform bootstrap process
    context.ordererProfile = config_util.PROFILE_TYPES.get(ordererType, "SampleInsecureSolo")
    channelID = context.interface.SYS_CHANNEL_ID
    if hasattr(context, "composition"):
        context.projectName = context.composition.projectName
    else:
        context.projectName = str(uuid.uuid1()).replace('-','')
    config_util.generateCrypto(context)
    config_util.generateConfig(context, channelID, config_util.CHANNEL_PROFILE, context.ordererProfile)
    compose_impl(context, context.composeFile, projectName=context.projectName)

@given(u'I have a bootstrapped fabric network of type {ordererType} using state-database {database} with tls')
def step_impl(context, ordererType, database):
    bootstrapped_impl(context, ordererType, database, True)

@given(u'I have a bootstrapped fabric network of type {ordererType} using state-database {database} without tls')
def step_impl(context, ordererType, database):
    bootstrapped_impl(context, ordererType, database, False)

@given(u'I have a bootstrapped fabric network of type {ordererType} using state-database {database}')
def step_impl(context, ordererType, database):
    bootstrapped_impl(context, ordererType, database, False)

@given(u'I have a bootstrapped fabric network using state-database {database} with tls')
def step_impl(context, database):
    bootstrapped_impl(context, "solo", database, True)

@given(u'I have a bootstrapped fabric network of type {ordererType} with tls')
def step_impl(context, ordererType):
    bootstrapped_impl(context, ordererType, "leveldb", True)

@given(u'I have a bootstrapped fabric network with tls')
def step_impl(context):
    bootstrapped_impl(context, "solo", "leveldb", True)

@given(u'I have a bootstrapped fabric network using state-database {database} without tls')
def step_impl(context, database):
    bootstrapped_impl(context, "solo", database, False)

@given(u'I have a bootstrapped fabric network using state-database {database}')
def step_impl(context, database):
    bootstrapped_impl(context, "solo", database, False)

@given(u'I have a bootstrapped fabric network of type {ordererType} without tls')
def step_impl(context, ordererType):
    bootstrapped_impl(context, ordererType, "leveldb", False)

@given(u'I have a bootstrapped fabric network of type {ordererType}')
def step_impl(context, ordererType):
    bootstrapped_impl(context, ordererType, "leveldb", False)

@given(u'I have a bootstrapped fabric network without tls')
def step_impl(context):
    bootstrapped_impl(context, "solo", "leveldb", False)

@given(u'I have a bootstrapped fabric network')
def step_impl(context):
    bootstrapped_impl(context, "solo", "leveldb", False)

@when(u'the initial leader peer of "{org}" is taken down by doing a {takeDownType}')
def step_impl(context, org, takeDownType):
    bringdown_impl(context, context.interface.get_initial_leader(context, org), takeDownType)

@when(u'the initial leader peer of "{org}" is taken down')
def step_impl(context, org):
    bringdown_impl(context, context.interface.get_initial_leader(context, org))

@when(u'the initial non-leader peer of "{org}" is taken down by doing a {takeDownType}')
def step_impl(context, org, takeDownType):
    bringdown_impl(context, context.interface.get_initial_non_leader(context, org), takeDownType)

@when(u'the initial non-leader peer of "{org}" is taken down')
def step_impl(context, org):
    bringdown_impl(context, context.interface.get_initial_non_leader(context, org))

@when(u'"{component}" is taken down by doing a {takeDownType}')
def step_impl(context, component, takeDownType):
    bringdown_impl(context, component, takeDownType)

@when(u'"{component}" is taken down')
def bringdown_impl(context, component, takeDownType="stop"):
    assert component in context.composition.collectServiceNames(), "Unknown component '{0}'".format(component)
    if takeDownType=="stop":
        context.composition.stop([component])
    elif takeDownType=="pause":
        context.composition.pause([component])
    elif takeDownType=="disconnect":
        context.composition.disconnect([component])
    else:
        assert False, "takedown process undefined: {}".format(context.takeDownType)

@when(u'the initial leader peer of "{org}" comes back up by doing a {bringUpType}')
def step_impl(context, org, bringUpType):
    bringup_impl(context, context.interface.get_initial_leader(context, org), bringUpType)

@when(u'the initial leader peer of "{org}" comes back up')
def step_impl(context, org):
    bringup_impl(context, context.interface.get_initial_leader(context, org))

@when(u'the initial non-leader peer of "{org}" comes back up by doing a {bringUpType}')
def step_impl(context, org, bringUpType):
    bringup_impl(context, context.interface.get_initial_non_leader(context, org), bringUpType)

@when(u'the initial non-leader peer of "{org}" comes back up')
def step_impl(context, org):
    bringup_impl(context, context.interface.get_initial_non_leader(context, org))

@when(u'"{component}" comes back up by doing a {bringUpType}')
def step_impl(context, component, bringUpType):
    bringup_impl(context, component, bringUpType)

@when(u'"{component}" comes back up')
def bringup_impl(context, component, bringUpType="start"):
    assert component in context.composition.collectServiceNames(), "Unknown component '{0}'".format(component)
    if bringUpType=="start":
        context.composition.start([component])
    elif bringUpType=="unpause":
        context.composition.unpause([component])
    elif bringUpType=="connect":
        context.composition.connect([component])
    else:
        assert False, "Bringing-up process undefined: {}".format(context.bringUpType)

@when(u'I start a fabric network using a {ordererType} orderer service with tls')
def start_network_impl(context, ordererType, tlsEnabled=True):
    assert ordererType in config_util.ORDERER_TYPES, "Unknown network type '%s'" % ordererType
    curpath = os.path.realpath('.')
    context.composeFile = "%s/docker-compose/docker-compose-%s.yml" % (curpath, ordererType)
    assert os.path.exists(context.composeFile), "The docker compose file does not exist: {0}".format(context.composeFile)

    # Should TLS be enabled
    context.tls = tlsEnabled
    if tlsEnabled:
        common_util.enableTls(context, tlsEnabled)

    compose_impl(context, context.composeFile, projectName=context.projectName)

@when(u'I start a fabric network using a {ordererType} orderer service')
def step_impl(context, ordererType):
    start_network_impl(context, ordererType, False)

@when(u'I start a fabric network')
def step_impl(context):
    start_network_impl(context, "solo", False)

@then(u'the initial non-leader peer of "{org}" has become the leader')
def step_impl(context, org):
    assert hasattr(context, 'initial_non_leader'), "Error: initial non-leader was not set previously. This statement works only with pre-set initial non-leader."
    assert common_util.is_in_log(context.initial_non_leader[org], "Becoming a leader"), "Error: initial non-lerader peer has not become leader."

@then(u'the initial non-leader peer of "{org}" has not become the leader')
def step_impl(context, org):
    assert hasattr(context, 'initial_non_leader'), "Error: initial non-leader was not set previously. This statement works only with pre-set initial non-leader."
    assert not comon_util.is_in_log(context.initial_non_leader[org], "Becoming a leader"), "Error: initial non-leader peer has already become leader."

@then(u'there are no errors')
def step_impl(context):
    pass
