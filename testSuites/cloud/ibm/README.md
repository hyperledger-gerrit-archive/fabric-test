
# Content for IBM Blockchain Platform (IBP) Networks

## Preparing the Network Connection Profile
Before executing tests on your network with a tool
such as fabric-test/testSuites/cloud/**runCloudPTE.sh**,
we must first create a network credentials file,
fabric-test/testSuites/cloud/IBM/creds/**network.json**,
and subsequently create the required connection profile.

First, create a network credentials **network.json** file and fill in the details manually.

* SHORTCUT ALTERNATIVE:
  __(Currently this option is supported only for IBP Starter Plan networks - but
  we hope to implement for other networks if the necessary APIs are made available).__
  We offer a shortcut to create the network.json network credentials file:
  by providing your Bluemix account org ID and API_Key to the script
  **create_network.sh**, it will create a service instance and also downloads
  the necessary network credentials to fabric-test/testSuites/cloud/IBM/creds/**network.json**
  for you, before proceeding.

Run **genConnProfile.sh** to generate the admin certs and create the connection profile.
The script generates admin certs, uploads them to the peers, and syncs the admin certs on the channel.
It also updates the connection profile to include those admin certs using IBP provided REST APIs.
Admin certs are essential for any client to perform administrative operations
like *create channel*, *join channel*, *install/instantiate/upgarde chaincode*, etc.

What does the script **genConnProfile.sh** do ?

* Using the Network credentials **network.json**, Downloads the **connection profiles** for the corresponding orgs
* Enroll admin user with CA and generates admin certificates through *fabric-ca-client* binary
* Uploads the certs to the peers and restart the peers using IBP specific REST APIs
* Syncs the admin certs on the channel using IBP specific REST APIs
* Update the admin cert/private key in the connection profile.
