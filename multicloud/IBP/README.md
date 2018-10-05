### IBP helper script to generate the admin certs

This is utility script intended for IBP Networks
The script primarily focuses on generating admin certs, uploading them to the peers and syncs the admin certs on the channel, Also updates connection profile to include those admin certs using IBP provided REST APIs. Admin certs are essential for  any client to perform admin operations like channel *creation*, *join*, *install*, *instantiate*/*upgarde chaincode* etc.,

There are two options to run this script with
1. Provide Bluemix account email ID and API_Key 
   Script will create a service instance and downloads the network credentials file ,  **network.json**
2. Provide the network credentials file **network.json** as input to the script

What does this script do ?
* Using the Network credentials **network.json**, Downloads the **connection profiles** for the corresponding orgs
* Enroll admin user with CA and generates admin certificates through *fabric-ca-client* binary
* Uploads the certs to the peers and restart the peers using IBP specific REST APIs
* Syncs the admin certs on the channel using IBP specific REST APIs
* Update the admin cert/private key in the connection profile.
