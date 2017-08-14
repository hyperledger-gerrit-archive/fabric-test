#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

import os
import sys
import datetime
from pykafka import KafkaClient
import Queue
import endorser_util
import grpc
from grpc.framework.interfaces.face.face import AbortionError
from grpc.beta.interfaces import StatusCode

try:
    pbFilePath = "../fabric/bddtests"
    sys.path.insert(0, pbFilePath)
    from common import common_pb2
    from orderer import ab_pb2, ab_pb2_grpc
except:
    print("ERROR! Unable to import the protobuf libraries from the ../fabric/bddtests directory: {0}".format(sys.exc_info()[0]))
    sys.exit(1)


def getKafkaBrokerList(context, orderer):
    # Get the kafka broker list from the orderer environment var
    kafkaBrokers = ""
    for container in context.composition.containerDataList:
        if orderer in container.containerName:
            kafkaBrokers = container.getEnv('CONFIGTX_ORDERER_KAFKA_BROKERS')
            break

    # Be sure that kafka broker list returned is not an empty string
    assert kafkaBrokers != "", "There are no kafka brokers set in the orderer environment"
    brokers = kafkaBrokers[1:-1].split(',')
    return brokers

def getKafkaIPs(context, kafkaList):
    kafkas = []
    for kafka in kafkaList:
        containerName = kafka.split(':')[0]
        container = context.composition.getContainerFromName(containerName, context.composition.containerDataList)
        kafkas.append("{0}:9092".format(container.ipAddress))
    return kafkas

def getKafkaTopic(kafkaBrokers=["0.0.0.0:9092"], channel=endorser_util.SYS_CHANNEL_ID):
    kafkas = ",".join(kafkaBrokers)
    client = KafkaClient(hosts=kafkas)
    if client.topics == {} and channel is None:
        topic = client.topics[endorser_util.TEST_CHANNEL_ID]
    elif client.topics == {} and channel is not None:
        topic = client.topics[channel]
    elif channel is not None and channel in client.topics:
        topic = client.topics[channel]
    elif channel is None and client.topics != {}:
        topic_list = client.topics.keys()
        topic = client.topics[topic_list[0]]

    # Print brokers in ISR
    print("ISR: {}".format(["kafka{}".format(broker.id) for broker in topic.partitions[0].isr]))
    return topic

def getKafkaPartitionLeader(kafkaBrokers=["0.0.0.0:9092"], channel=endorser_util.SYS_CHANNEL_ID):
    topic = getKafkaTopic(kafkaBrokers, channel)
    leader = "kafka{0}".format(topic.partitions[0].leader.id)
    print("current leader: {}".format(leader))
    return leader

def getNonISRKafkaBroker(kafkaBrokers=["0.0.0.0:9092"], channel=endorser_util.SYS_CHANNEL_ID):
    topic = getKafkaTopic(kafkaBrokers, channel)
    kafka = None
    for kafkaNum in range(len(kafkaBrokers)):
        if str(kafkaNum) not in topic.partitions[0].isr:
            kafka = "kafka{0}".format(kafkaNum)
    return kafka

def generateMessageEnvelope():
    channel_header = common_pb2.ChannelHeader(channel_id=endorser_util.TEST_CHANNEL_ID,
                                              type=common_pb2.ENDORSER_TRANSACTION)
    header = common_pb2.Header(channel_header=channel_header.SerializeToString(),
                               signature_header=common_pb2.SignatureHeader().SerializeToString())
    payload = common_pb2.Payload(header=header,
                                 data=str.encode("Functional test: {0}".format(datetime.datetime.utcnow())) )
    envelope = common_pb2.Envelope(payload=payload.SerializeToString())
    return envelope

def _testAccessPBMethods():
    envelope = generateMessageEnvelope()
    assert isinstance(envelope, common_pb2.Envelope), "Unable to import protobufs from bddtests directory"


################################################################################################
def seekPosition(position):
    if position == 'Oldest':
        return ab_pb2.SeekPosition(oldest=ab_pb2.SeekOldest())
    elif position == 'Newest':
        return ab_pb2.SeekPosition(newest=ab_pb2.SeekNewest())
    else:
        return ab_pb2.SeekPosition(specified=ab_pb2.SeekSpecified(number=position))

def convertSeek(inputString):
    if inputString.isdigit():
        return int(inputString)
    else:
        return str(inputString)

def getGRPCChannel(ipAddress, port, root_certificates, ssl_target_name_override):
    creds = grpc.ssl_channel_credentials(root_certificates=root_certificates)
    channel = grpc.secure_channel("{0}:{1}".format(ipAddress, port), creds,
                                  options=(('grpc.ssl_target_name_override',
                                            ssl_target_name_override,),
                                           ('grpc.default_authority',
                                            ssl_target_name_override,),
                                           ('grpc.max_receive_message_length',
                                            100*1024*1024)))

    # print("Returning GRPC for address: {0}".format(ipAddress))
    return channel

class StreamHelper():
    def __init__(self):
        self.streamClosed = False
        self.sendQueue = Queue.Queue()
        self.receiveQueue = Queue.Queue()
        self.receivedMessages = []
        self.replyGenerator = None

    def createSendGenerator(self, timeout=30):
        while True:
            try:
                nextMsg = self.sendQueue.get(True, timeout)
                if nextMsg:
                    yield nextMsg
                else:
                    return
            except Queue.Empty:
                return

    def readMessages(self, expectedCount):
        msgsReceived = []
        counter = 0
        try:
            for reply in self.replyGenerator:
                counter += 1
                msgsReceived.append(reply)
                if counter == int(expectedCount):
                    break
        except AbortionError as networkError:
            self.handleNetworkError(networkError)
        return msgsReceived

    def send(self, msg):
        if msg:
            if self.streamClosed:
                raise Exception("Stream is closed")
        self.sendQueue.put(msg)

    def handleNetworkError(self, networkError):
        if networkError.code == StatusCode.OUT_OF_RANGE and networkError.details == "EOF":
            print("Error received and ignored: {0}".format(networkError))
            self.streamClosed = True
        else:
            raise Exception("Unexpected NetworkError: {0}".format(networkError))


class Registration():
    def __init__(self, userName):
        self.userName= userName
        # Dictionary of composeService->atomic broadcast grpc Stub
        self.atomicBroadcastStubsDict = {}
        # composeService->StreamHelper
        self.abDeliversStreamHelperDict = {}

    def closeStreams(self):
        for compose_service, deliverStreamHelper in self.abDeliversStreamHelperDict.iteritems():
            deliverStreamHelper.send(None)
        self.abDeliversStreamHelperDict.clear()

    def connectToDeliverFunction(self, context, composeService, nodeAdminTuple, timeout=1):
        'Connect to the deliver function and drain messages to associated orderer queue'
        assert not composeService in self.abDeliversStreamHelperDict, "Already connected to deliver stream on {0}".format(composeService)
        streamHelper = DeliverStreamHelper(ordererStub=self.getABStubForComposeService(context=context,
                                                                                       composeService=composeService),
                                           entity=self, nodeAdminTuple=nodeAdminTuple)
        self.abDeliversStreamHelperDict[composeService] = streamHelper
        return streamHelper

    def getDelivererStreamHelper(self, context, composeService):
        assert composeService in self.abDeliversStreamHelperDict, "NOT connected to deliver stream on {0}".format(composeService)
        return self.abDeliversStreamHelperDict[composeService]

    def broadcastMessages(self, context, numMsgsToBroadcast, composeService, dataFunc=generateMessageEnvelope):
        abStub = self.getABStubForComposeService(context, composeService)
        replyGenerator = abStub.Broadcast(generateBroadcastMessages(numToGenerate = int(numMsgsToBroadcast), dataFunc=dataFunc), 2)
        counter = 0
        try:
            for reply in replyGenerator:
                counter += 1
                print("{0} received reply: {1}, counter = {2}".format(self.getUserName(), reply, counter))
                if counter == int(numMsgsToBroadcast):
                    break
        except Exception as e:
            print("Got error: {0}".format(e) )
        #assert counter == int(numMsgsToBroadcast), "counter = {0}, expected {1}".format(counter, numMsgsToBroadcast)

    def getABStubForComposeService(self, context, composeService):
        'Return a Stub for the supplied composeService, will cache'
        if composeService in self.atomicBroadcastStubsDict:
            return self.atomicBroadcastStubsDict[composeService]
        # Get the IP address of the server that the user registered on
        #root_certificates = getTrustedRootsForOrdererNetworkAsPEM()
        ipAddress, port = compose_util.getPortHostMapping(context.compose_containers, composeService, 7050)
        # print("ipAddress in getABStubForComposeService == {0}:{1}".format(ipAddress, port))
        channel = getGRPCChannel(ipAddress=ipAddress, port=port, ssl_target_name_override=composeService)
        newABStub = ab_pb2_grpc.AtomicBroadcastStub(channel)
        self.atomicBroadcastStubsDict[composeService] = newABStub
        return newABStub

