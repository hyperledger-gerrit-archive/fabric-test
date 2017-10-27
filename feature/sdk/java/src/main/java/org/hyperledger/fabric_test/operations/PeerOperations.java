package org.hyperledger.fabric_test.operations;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import org.bouncycastle.crypto.util.PrivateKeyFactory;
import org.bouncycastle.openssl.PEMWriter;
import com.google.gson.*;
import com.google.gson.reflect.TypeToken;
import org.hyperledger.fabric.sdk.exception.*;
import org.hyperledger.fabric_ca.sdk.exception.EnrollmentException;
import org.hyperledger.fabric_ca.sdk.exception.InfoException;
import org.hyperledger.fabric_test.structures.AppUser;
import org.apache.log4j.BasicConfigurator;
//import org.apache.log4j.Level;
//import org.apache.log4j.Logger;
import org.apache.commons.lang.WordUtils;
//import org.bouncycastle.asn1.x500.style.BCStyle;
//import org.bouncycastle.asn1.x500.style.IETFUtils;
//import org.bouncycastle.cert.jcajce.JcaX509CertificateHolder;
import org.bouncycastle.util.encoders.Base64;
import org.hyperledger.fabric.sdk.*;
import org.hyperledger.fabric.sdk.NetworkConfig.CAInfo;
import org.hyperledger.fabric.sdk.NetworkConfig.UserInfo;
import org.hyperledger.fabric.sdk.security.CryptoSuite;
import org.hyperledger.fabric_ca.sdk.EnrollmentRequest;
import org.hyperledger.fabric_ca.sdk.HFCAClient;
import org.hyperledger.fabric_ca.sdk.HFCAInfo;

import java.io.*;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Type;
import java.nio.charset.Charset;
//import java.nio.file.FileAlreadyExistsException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
//import java.security.PublicKey;
//import java.security.cert.CertificateFactory;
//import java.security.cert.X509Certificate;
import java.security.PrivateKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.X509EncodedKeySpec;
import java.util.*;
import java.util.AbstractMap.SimpleEntry;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class PeerOperations {

    // Globals
    //   Configuration Path
    @Parameter(names={"--configpath", "-c"})
    private static String configPath = "../../configs";

    //   Peer name
    @Parameter(names={"--peername", "-n"})
    String peerName = "peer0.org1.example.com";
     //   Peer IP address
    @Parameter(names={"--peerip", "-i"})
    String peerIp;
    //   Peer port
    @Parameter(names={"--peerport", "-p"})
    String peerPort;
    //   Command
    @Parameter(names={"--operation", "-o"})
    String operationStr;
    //   Organization Name
    @Parameter(names={"--mspid", "-r"})
    String mspId = "org1.example.com";
    //   Orderer
    @Parameter(names={"--orderer", "-d"})
    String orderer = "orderer0.example.com";
    //   Network ID
    @Parameter(names={"--networkid", "-e"})
    String networkID = "";
    //   CA Certificate Path
    @Parameter(names={"--cacertpath", "-a"})
    String cacertPath;
    //   Server CA Certificate Path
    @Parameter(names={"--srvcertpath", "-s"})
    String srvcertPath;

    //   Channel Name
    @Parameter(names={"--channelname", "-h"})
    String channelName;
    //   Chaincode Name
    @Parameter(names={"--ccname", "-m"})
    String ccName;
    //   Chaincode version
    @Parameter(names={"--ccversion", "-v"})
    String ccVersion;
    //   Chaincode Path
    @Parameter(names={"--ccpath", "-t"})
    String ccPath;
    //   Chaincode Func
    @Parameter(names={"--ccfunc", "-f"})
    String ccFunc;
    //   Chaincode Args
    @Parameter(names={"--ccargs", "-g"})
    String ccargs;

    //   UserName
    @Parameter(names={"--user", "-u"})
    String userName;
    //   User Password
    @Parameter(names={"--userpasswd", "-w"})
    String userPassword;

    private static Map<String, Operation> operationMap() {
        return Collections.unmodifiableMap(Stream.of(
                new SimpleEntry<>("join", Operation.CHANNEL_JOIN),
                new SimpleEntry<>("install", Operation.CC_INSTALL),
                new SimpleEntry<>("instantiate", Operation.CC_INSTANTIATE),
                new SimpleEntry<>("upgrade", Operation.CC_UPGRADE),
                new SimpleEntry<>("query", Operation.CC_QUERY),
                new SimpleEntry<>("invoke", Operation.CC_INVOKE)
        ).collect(Collectors.toMap(SimpleEntry::getKey, SimpleEntry::getValue)));
    }
    private static JsonObject connectionProfile;

    public static void main(String ... argv) throws Exception {
        PeerOperations main = new PeerOperations();
        JCommander.newBuilder()
                .addObject(main)
                .build()
                .parse(argv);
        main.run();
    }

    public void run() throws IOException, InvalidArgumentException, ProposalException, TransactionException, IllegalAccessException, InstantiationException, ClassNotFoundException, NoSuchMethodException, InvocationTargetException, CryptoException, InfoException, org.hyperledger.fabric_ca.sdk.exception.InvalidArgumentException, EnrollmentException, InvalidKeySpecException, NoSuchAlgorithmException, NetworkConfigurationException {
        BasicConfigurator.configure();

        // Using enums and putting this check up here instead of just using a switch-case statement directly
        // so as to avoid unnecessary overhead by setting up client and peer
        Operation operation = operationMap().getOrDefault(operationStr, Operation.INVALID);
        if (operation == Operation.INVALID) {
            System.out.println("Unknown command.");
            System.exit(1);
        }

        String orgName = WordUtils.capitalize(mspId.replace(".", " ")).replace(" ", "");
        connectionProfile = getConnectionProfile();
        String enrollId = String.format("%s@%s", userName, mspId);

        HFClient _client = HFClient.createNewInstance();
        _client.setCryptoSuite(CryptoSuite.Factory.getCryptoSuite());

        AppUser appUser = new AppUser(enrollId, orgName, mspId);

        JsonObject ordererInfo = getOrderer(connectionProfile, "orderer0.example.com");

        Properties ordererProperties = new Properties();
        ordererProperties.put("pemBytes", ordererInfo.getAsJsonObject("tlsCACerts").get("pem").getAsString().getBytes());
        ordererProperties.put("grpc.NettyChannelBuilderOption.keepAliveTime",
                ordererInfo.getAsJsonObject("grpcOptions").get("grpc.keepalive_time_ms").getAsInt());
                //ordererInfo.getAsJsonObject("grpcOptions").get("grpc.http2.keepalive_time").getAsInt());
        ordererProperties.put("grpc.NettyChannelBuilderOption.keepAliveTimeout",
                ordererInfo.getAsJsonObject("grpcOptions").get("grpc.keepalive_timeout_ms").getAsInt());
                //ordererInfo.getAsJsonObject("grpcOptions").get("grpc.http2.keepalive_timeout").getAsInt());
        ordererProperties.put("grpc.NettyChannelBuilderOption.keepAliveWithoutCalls", new Object[] {true});

        JsonObject peerInfo = connectionProfile.getAsJsonObject("peers").getAsJsonObject(peerName);
        String peerLocation = peerInfo.get("url").getAsString();

        Properties peerProperties = new Properties();
        peerProperties.put("pemBytes",
                peerInfo.getAsJsonObject("tlsCACerts").get("pem").getAsString().getBytes());

        //Example of setting specific options on grpc's NettyChannelBuilder
        peerProperties.put("grpc.NettyChannelBuilderOption.maxInboundMessageSize", 9000000);

        appUser.setEnrollment(getEnrollment(connectionProfile, mspId, enrollId, userPassword));
        _client.setUserContext(appUser);

        Orderer orderer = _client.newOrderer( "orderer0.example.com",
                ordererInfo.get("url").getAsString(),
                ordererProperties);
        Peer peer = _client.newPeer(peerName, peerLocation, peerProperties);
        Channel channel = getChannel(channelName, _client);
        channel.addOrderer(orderer);
        channel.initialize();


//        if (!setupHFClient(_client, connectionProfile, orderer, mspId, userName, userPassword)) {
//            System.out.printf("Unable to setup the client for the user %s@%s.\n", userName, mspId);
//            System.exit(1);
//        }

//        System.out.println("Setup peer service...");
//        Properties peerProperties = new Properties();
//        String rootCert;
//        String peerUrl;
//        byte[] srvCertBytes;
//        rootCert = peerInfo.getAsJsonObject("tlsCACerts").get("pem").getAsString();
//        peerUrl = peerInfo.get("url").getAsString();

        //peerProperties.put("pemBytes", new String(Files.readAllBytes(rootCertFile)));
//        peerProperties.put("pemBytes", rootCert);
//        Peer peer = _client.newPeer(
//                peerName,
//                peerUrl,
//                peerProperties
//        );

        System.out.println("Perform operation...");
        if (operation == Operation.CC_INSTALL) {
            installChaincode(ccName, ccVersion, ccPath, _client, Collections.singletonList(peer));
            System.exit(0);
        }

        if (operation != Operation.CHANNEL_JOIN) {
            channel.addPeer(peer);
            channel.initialize();
        }

        // Cases CC_INSTALL and INVALID are unreachable at this point
        switch (operation) {
            case CHANNEL_JOIN:
                joinChannel(channel, peer);
                break;
            case CC_INSTANTIATE: {
                ArrayList<String> ccArgs = arrayFromJsonString(ccargs);
                instantiateChaincode(ccName, ccVersion, channel, ccArgs, _client, Collections.singletonList(peer));
                break;
            }
            case CC_UPGRADE: {
                upgradeChaincode(ccName, ccVersion, channel, _client, Collections.singletonList(peer));
                break;
            }
            case CC_QUERY: {
                ArrayList<String> ccArgs = arrayFromJsonString(ccargs);
                sendQuery(ccName, ccFunc, ccArgs, channel, _client);
                break;
            }
            case CC_INVOKE: {
                ArrayList<String> ccArgs = arrayFromJsonString(ccargs);
                invokeTransaction(ccName, ccFunc, ccArgs, channel, _client, Collections.singletonList(peer));
                break;
            }
        }
    }

    private static boolean setupHFClient(HFClient client, JsonObject connectionProfile, String ord, String mspId, String user, String password) throws IOException, IllegalAccessException, InvocationTargetException, InvalidArgumentException, InstantiationException, NoSuchMethodException, CryptoException, ClassNotFoundException, org.hyperledger.fabric_ca.sdk.exception.InvalidArgumentException, InfoException, EnrollmentException, NetworkConfigurationException {
        boolean loadedFromPersistence = false;
        String org = WordUtils.capitalize(mspId.replace(".", " ")).replace(" ", "");
        //Properties props = new Properties();
        String enrollId = String.format("%s@%s", user, mspId);

        AppUser appUser = new AppUser(enrollId, org, mspId);

        System.out.println(connectionProfile);
        String caName = String.format("ca.%s", mspId);

        String caUrl = connectionProfile.getAsJsonObject("certificateAuthorities").getAsJsonObject(caName).get("url").getAsString();

        File configFile = new File(Paths.get(configPath, "network-config.json").toString());
        NetworkConfig config = NetworkConfig.fromJsonFile(configFile);
        NetworkConfig.OrgInfo orgInfo = config.getOrganizationInfo(org);
        CAInfo caInfo = orgInfo.getCertificateAuthorities().get(0);

        // Enroll using Fabric-CA
        HFCAClient caClient = HFCAClient.createNewInstance(caInfo);
        caClient.setCryptoSuite(CryptoSuite.Factory.getCryptoSuite());
        Collection<UserInfo> registrars = caInfo.getRegistrars();
        UserInfo registrar = registrars.iterator().next();
        Enrollment enroll = caClient.enroll(enrollId, password);
        registrar.setEnrollment(enroll);



        //HFCAClient caClient = HFCAClient.createNewInstance(caName, caUrl, props);
        System.out.println("NewInstance of CA Client");
        //caClient.setCryptoSuite(CryptoSuite.Factory.getCryptoSuite());
        System.out.println("CA Client crypto");

        assert caClient.info() != null : "caClient.info() is null.";
        assert client.getUserContext() == null : "userContext is not null";

        System.out.printf("CA Client info: name: %s ... status: %s ... stuff: %s", caClient.getCAName(), caClient.getStatusCode(), caClient.toString());

        //String networkId = connectionProfile.get("networkID").getAsString();

        Path userPath = Paths.get(configPath, "peerOrganizations", mspId, "users", enrollId);
        if (Files.exists(userPath)) {
            //Path certPath = Paths.get(configPath,"peerOrganizations", mspId, "users", enroll, "tls", "client.crt");
            //Path certPath = Paths.get(configPath,"peerOrganizations", mspId, "users", enrollId, "tls", "client.key");

            Path filePath = Paths.get(configPath,"peerOrganizations", mspId, "users", enrollId, "msp", "keystore");
            File keyDir = new File(filePath.toString());
            File[] listOfFiles = keyDir.listFiles();
            System.out.println(filePath.toString());
            assert listOfFiles != null : "There are no files in the filepath";
            System.out.println(listOfFiles[0].getName());
//            Path keyPath = Paths.get(configPath,"peerOrganizations", mspId, "users", enrollId, "msp", "keystore", listOfFiles[0].getName());
//            String keyString = new String(Files.readAllBytes(keyPath));
//            PrivateKey keyPem = getPrivateKeyFromPEMString(keyString);
            //PrivateKey keyPem = getPrivateKeyFromPEMString(Files.readAllBytes(keyPath));
//            Path certPath = Paths.get(configPath,"peerOrganizations", mspId, "users", enrollId, "msp", "signcerts", String.format("%s-cert.pem", enrollId));
//            String certPem = new String(Files.readAllBytes(certPath));

            System.out.println("CA Client enrolling...");
            appUser.setEnrollment(caClient.enroll(enrollId, password));
//            final EnrollmentRequest enrollmentRequest = new EnrollmentRequest();
//            enrollmentRequest.addHost(caUrl);
//            enrollmentRequest.setProfile("tls");
//            Enrollment userEnrollment = caClient.enroll(enrollId, password, enrollmentRequest);
//            Enrollment userEnrollment = new Enrollment() {
//                @Override
//                public PrivateKey getKey() {
//                    return keyPem;
//                }
//                @Override
//                public String getCert() {
//                    return certPem;
//                }
//            };
//            appUser.setEnrollment(userEnrollment);

//            assert certPem == userEnrollment.getCert() : "user certs from CA and local do not match.";
//            assert getPEMStringFromPrivateKey(userEnrollment.getKey()) == keyPem : "key certs from CA and local do not match.";

            System.out.println("Set new app user...");
            //appUser = new AppUser(enrollId, org, mspId, userEnrollment);
            client.setUserContext(appUser);

            loadedFromPersistence = true;
        }
        return loadedFromPersistence;
    }

    private static Enrollment getEnrollment(JsonObject connectionProfile, String mspId, String enrollId, String password) throws NetworkConfigurationException, IOException, InvalidArgumentException, org.hyperledger.fabric_ca.sdk.exception.InvalidArgumentException, IllegalAccessException, InvocationTargetException, InstantiationException, NoSuchMethodException, CryptoException, ClassNotFoundException, EnrollmentException {
        String caName = String.format("ca.%s", mspId);
        String caUrl = connectionProfile.getAsJsonObject("certificateAuthorities").getAsJsonObject(caName).get("url").getAsString();
        String org = WordUtils.capitalize(mspId.replace(".", " ")).replace(" ", "");

        File configFile = new File(Paths.get(configPath, "network-config.json").toString());
        NetworkConfig config = NetworkConfig.fromJsonFile(configFile);
        NetworkConfig.OrgInfo orgInfo = config.getOrganizationInfo(org);
        CAInfo caInfo = orgInfo.getCertificateAuthorities().get(0);
        System.out.println(caInfo.getCAName());

        // Enroll using Fabric-CA
        HFCAClient caClient = HFCAClient.createNewInstance(caInfo);
        caClient.setCryptoSuite(CryptoSuite.Factory.getCryptoSuite());

        EnrollmentRequest enrollmentRequest = new EnrollmentRequest();
        enrollmentRequest.addHost(caUrl);
        enrollmentRequest.setProfile("tls");
        return caClient.enroll(enrollId, password, enrollmentRequest);
    }

    private static JsonObject getOrderer(JsonObject connectionProfile, String ord) {
        JsonObject orderers = connectionProfile.getAsJsonObject("orderers").getAsJsonObject();
        return orderers.getAsJsonObject(ord);
    }

    private static JsonObject getConnectionProfile() throws IOException {
        String connectionProfileStr =
                new String(Files.readAllBytes(Paths.get(configPath, "network-config.json")));
        return new JsonParser().parse(connectionProfileStr).getAsJsonObject();
    }

    private static <T> ArrayList<T> arrayFromJsonString(String jsonArrayStr) {
        JsonArray jsonArray = new JsonParser().parse(jsonArrayStr).getAsJsonArray();
        Type type = new TypeToken<ArrayList<T>>() {}.getType();
        return new Gson().fromJson(jsonArray, type);
    }

    private static String getPEMStringFromPrivateKey(PrivateKey privateKey) throws IOException {
        StringWriter pemStrWriter = new StringWriter();
        PEMWriter pemWriter = new PEMWriter(pemStrWriter);
        pemWriter.writeObject(privateKey);
        pemWriter.close();
        return pemStrWriter.toString();
    }

    //private static PrivateKey getPrivateKeyFromPEMString(byte[] privateBytes) throws IOException, NoSuchAlgorithmException, InvalidKeySpecException {
    private static PrivateKey getPrivateKeyFromPEMString(String privatePem) throws IOException, NoSuchAlgorithmException, InvalidKeySpecException {
        //byte[] privateBytes = Base64.decode(privatePem);
        byte[] privateBytes = java.util.Base64.getDecoder().decode(privatePem);
        X509EncodedKeySpec keySpec = new X509EncodedKeySpec(privateBytes);
        KeyFactory keyFactory = KeyFactory.getInstance("DSA");
        PrivateKey priKey = keyFactory.generatePrivate(keySpec);
        return priKey;
    }

    private static Channel getChannel(String channelName, HFClient client)
            throws InvalidArgumentException, NetworkConfigurationException, IOException {
        System.out.println("Fetching channel " + channelName);

        //ChannelConfiguration channelConfiguration = new ChannelConfiguration(new File(configPath + String.format("%s.tx", channelName)));
        //Channel newChannel = client.newChannel(channelName,
        //        orderer,
        //        channelConfiguration,
        //        client.getChannelConfigurationSignature(channelConfiguration, appUser));

        File configFile = new File(Paths.get(configPath, "network-config.json").toString());
        NetworkConfig config = NetworkConfig.fromJsonFile(configFile);
        Channel channel = client.loadChannelFromConfig(channelName, config);

        //Channel channel = client.newChannel(channelName);

        Properties ordererProperties = new Properties();
        ordererProperties.put("pemBytes",
                connectionProfile.getAsJsonObject("orderers")
                        .getAsJsonObject("orderer0.example.com")
                        .getAsJsonObject("tlsCACerts").get("pem").getAsString().getBytes());
        Orderer orderer = client.newOrderer(
                "orderer0.example.com",
                connectionProfile.getAsJsonObject("orderers")
                        .getAsJsonObject("orderer0.example.com").get("url").getAsString(),
                ordererProperties
        );
        channel.addOrderer(orderer);

        return channel;
    }

    private static void joinChannel(Channel channel, Peer peer) {
        System.out.println("Joining channel...");

        try {
            channel.joinPeer(peer);
            System.out.println("Joined channel " + channel.getName());
        } catch (ProposalException ex) {
            System.out.println("Channel join failed. Is the peer " + peer.getName()
                    + " already joined to channel " + channel.getName() + "?");
            ex.printStackTrace();
        }
    }

    private static void installChaincode(String ccName, String ccVersion, String ccPath,
                                         HFClient client, Collection<Peer> peers)
            throws InvalidArgumentException, ProposalException {
        System.out.println("Installing chaincode " + ccName + ":" + ccVersion + " (located at $GOPATH/src/" + ccPath
        + " on peers " + peers + ".");
        InstallProposalRequest installProposalRequest = client.newInstallProposalRequest();
        String gopath = Paths.get(System.getenv("GOPATH")).toString();
        installProposalRequest.setChaincodeSourceLocation(new File(gopath));
        installProposalRequest.setChaincodeName(ccName);
        installProposalRequest.setChaincodeVersion(ccVersion);
        installProposalRequest.setChaincodePath(ccPath);
        installProposalRequest.setArgs(new ArrayList<>());
        client.sendInstallProposal(installProposalRequest, peers);
    }

    private static void instantiateChaincode(String ccName, String ccVersion,
                                             Channel channel, ArrayList<String> ccArgs,
                                             HFClient client, Collection<Peer> peers)
            throws InvalidArgumentException, ProposalException {
        System.out.println("Instantiating chaincode " + ccName + ":" + ccVersion
                + " on channel " + channel.getName() + ".");
        InstantiateProposalRequest instantiateRequest = client.newInstantiationProposalRequest();
        instantiateRequest.setChaincodeName(ccName);
        instantiateRequest.setChaincodeVersion(ccVersion);
        instantiateRequest.setArgs(ccArgs);
        instantiateRequest.setTransientMap(Collections.emptyMap());

        Collection<ProposalResponse> responses = channel.sendInstantiationProposal(instantiateRequest, peers);

        System.out.println("Sending transaction to orderer to be committed in the ledger.");
        channel.sendTransaction(responses, client.getUserContext());
        System.out.println("Transaction committed successfully.");
    }

    private static void upgradeChaincode(String ccName, String ccVersion,
                                         Channel channel, HFClient client, Collection<Peer> peers)
            throws InvalidArgumentException, ProposalException {
        System.out.println("Upgrading chaincode " + ccName + " to version " + ccVersion
                + " on channel " + channel.getName() + ".");
        UpgradeProposalRequest upgradeRequest = client.newUpgradeProposalRequest();
        upgradeRequest.setChaincodeName(ccName);
        upgradeRequest.setChaincodeVersion(ccVersion);
        upgradeRequest.setArgs(new ArrayList<>());
        upgradeRequest.setTransientMap(Collections.emptyMap());

        Collection<ProposalResponse> responses = channel.sendUpgradeProposal(upgradeRequest, peers);

        System.out.println("Sending transaction to orderer to be committed in the ledger.");
        channel.sendTransaction(responses, client.getUserContext());
        System.out.println("Transaction committed successfully.");
    }

    private static void sendQuery(String ccName, String function, List<String> args,
                                  Channel channel, HFClient client)
            throws InvalidArgumentException, ProposalException {
        System.out.println("Querying " + channel.getName() + " with function " + function + " using " + ccName + ".");
        QueryByChaincodeRequest query = client.newQueryProposalRequest();
        query.setChaincodeID(ChaincodeID.newBuilder()
                .setName(ccName)
                .build());
        query.setChaincodeName(ccName);
        query.setFcn(function);
        query.setArgs(new ArrayList<>(args));

        ArrayList<ProposalResponse> responses = new ArrayList<>(channel.queryByChaincode(query));
        System.out.println("Response:");
        Gson gson = new GsonBuilder().setPrettyPrinting().create();
        JsonParser parser = new JsonParser();
        JsonElement element = parser.parse(new String(responses.get(0).getChaincodeActionResponsePayload(),
                Charset.defaultCharset()));
        System.out.println(gson.toJson(element));
    }

    private static void invokeTransaction(String ccName, String function, List<String> args,
                                          Channel channel, HFClient client, Collection<Peer> peers)
            throws InvalidArgumentException, ProposalException {
        System.out.println("Sending transaction proposal to " + channel.getName() + " with function "
                + function + " using " + ccName + ".");
        TransactionProposalRequest invokeRequest = client.newTransactionProposalRequest();
        invokeRequest.setChaincodeID(ChaincodeID.newBuilder()
                .setName(ccName)
                .build());
        invokeRequest.setChaincodeName(ccName);
        invokeRequest.setFcn(function);
        invokeRequest.setArgs(new ArrayList<>(args));

        Collection<ProposalResponse> responses = channel.sendTransactionProposal(invokeRequest, peers);

        System.out.println("Sending transaction to orderer to be committed in the ledger.");
        channel.sendTransaction(responses, client.getUserContext());
    }

    private enum Operation {
        CHANNEL_JOIN, CC_INSTALL, CC_INSTANTIATE, CC_UPGRADE, CC_QUERY, CC_INVOKE, INVALID
    }
}
