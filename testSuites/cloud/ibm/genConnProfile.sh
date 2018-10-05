#!/bin/bash

if [ ! -f network.json ]; then
	printf "\n ERROR : Make sure to include the (Network Credentials) network.json under ${PWD} dir\n\n"
	exit 1
fi

export PATH=$PATH:$PWD/bin/
PROG="[helio-apis]"
export CONNECTION_PROF_DIR=creds/connectionprofiles

rm -rf bin cacert.pem creds


####################
# Helper Functions #
####################

function log() {
	printf "${PROG}  ${1}\n"
}

function get_pem() {
	awk '{printf "%s\\n", $0}' creds/org"$1"admin/msp/signcerts/cert.pem
}

function banner(){
	echo "########################################################################"
	printf "$1\n"
	echo "########################################################################"
	echo
}

function alert(){
	if [ $1 -ne 0 ]; then
		printf "\n--------------------------------------------------------------------\n"
		printf "!!! ERROR : Failed to $2"
		printf "\n--------------------------------------------------------------------\n"
		exit
	else
		printf "\nSuccessfully $2\n"
	fi
}

## Get the First Orgname from Network credentails
ORG1_NAME=$(jq -r "[.[] | .key][0]" network.json)
if [ "$ORG1_NAME" =  "PeerOrg1" ]; then
	IS_ENTERPRISE=true
	export CA_VERSION=1.1.0
	export CHANNEL_NAME=${1:-channel1}
else
	export CA_VERSION=1.2.0
	export CHANNEL_NAME=defaultchannel
fi

API_ENDPOINT=$(jq -r .\"${ORG1_NAME}\".url network.json)
NETWORK_ID=$(jq -r .\"${ORG1_NAME}\".network_id network.json)

ORG1_API_KEY=$(jq -r .\"${ORG1_NAME}\".key network.json)
ORG1_API_SECRET=$(jq -r .\"${ORG1_NAME}\".secret network.json)

banner "Extract Information from Network Credentails\n\nAPI_ENDPOINT = ${API_ENDPOINT}\nNETWORK_ID = ${NETWORK_ID}\nORG1_API_KEY = ${ORG1_API_KEY}\nORG1_API_SECRET=${ORG1_API_SECRET}\n"
echo
log "Downloading the Connection profile for ${ORG1_NAME}\n"
mkdir -p ${CONNECTION_PROF_DIR}
curl -s -X GET --header 'Content-Type: application/json' --header 'Accept: application/json' --basic --user ${ORG1_API_KEY}:${ORG1_API_SECRET} ${API_ENDPOINT}/api/v1/networks/${NETWORK_ID}/connection_profile | jq . >& ${CONNECTION_PROF_DIR}/org1.json
alert $? "download[ed] the connection profile for Org ${ORG1_NAME}\n"

ORG1_PEER_NAME=$(jq -r .organizations.\"${ORG1_NAME}\".peers[0] ${CONNECTION_PROF_DIR}/org1.json)
ORG1_CA_NAME=$(jq -r .organizations.\"${ORG1_NAME}\".certificateAuthorities[0] ${CONNECTION_PROF_DIR}/org1.json)
ORG1_CA_URL=$(jq -r .certificateAuthorities.\"$ORG1_CA_NAME\".url ${CONNECTION_PROF_DIR}/org1.json | cut -d '/' -f 3)
ORG1_ENROLL_SECRET=$(jq -r .certificateAuthorities.\"$ORG1_CA_NAME\".registrar[0].enrollSecret ${CONNECTION_PROF_DIR}/org1.json)
banner "Extract Information from ${ORG1_NAME} Connection profile\n\nORG1_PEER_NAME = ${ORG1_PEER_NAME}\nORG1_CA_URL = ${ORG1_CA_URL}\nORG1_ENROLL_SECRET = ${ORG1_ENROLL_SECRET}\n"

############################################################
# STEP 1 - generate user certs and upload to remote fabric #
############################################################
# save the cert
jq -r .certificateAuthorities.\"${ORG1_CA_NAME}\".tlsCACerts.pem ${CONNECTION_PROF_DIR}/org1.json > cacert.pem

export ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
if [ ! -f bin/fabric-ca-client ]; then
	curl -s https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric-ca/hyperledger-fabric-ca/${ARCH}-${CA_VERSION}/hyperledger-fabric-ca-${ARCH}-${CA_VERSION}.tar.gz | tar xz
	alert $? "download[ed] the fabric-ca-client binary\n\n"
else
	log "fabric-ca-client already exists ... skipping download\n\n"
fi

log "Enrolling admin user for ${ORG1_NAME}.\n"
export FABRIC_CA_CLIENT_HOME=${PWD}/creds/org1admin
fabric-ca-client enroll --tls.certfiles ${PWD}/cacert.pem -u https://admin:${ORG1_ENROLL_SECRET}@${ORG1_CA_URL} --mspdir ${PWD}/creds/org1admin/msp

# rename the keyfile
mv creds/org1admin/msp/keystore/* creds/org1admin/msp/keystore/priv.pem

# upload the cert
BODY1=$(cat <<EOF1
{
	"msp_id": "${ORG1_NAME}",
	"adminCertName": "PeerAdminCert1",
	"adminCertificate": "$(get_pem 1)",
	"peer_names": [
		"${ORG1_PEER_NAME}"
	],
	"SKIP_CACHE": true
}
EOF1
)
printf "\n\n"
log " Uploading admin certificate for ${ORG1_NAME}."
curl -s -X POST \
	--header 'Content-Type: application/json' \
	--header 'Accept: application/json' \
	--basic --user ${ORG1_API_KEY}:${ORG1_API_SECRET} \
	--data "${BODY1}" \
    ${API_ENDPOINT}/api/v1/networks/${NETWORK_ID}/certificates
echo

##########################
# STEP 2 - restart peers #
##########################
# STEP 2.1 - ORG1
printf "\n"
log " Restarting Peer(s) of ${ORG1_NAME}."
PEER=${ORG1_PEER_NAME}
log "Stoping ${PEER}"
curl -s -X POST \
	--header 'Content-Type: application/json' \
	--header 'Accept: application/json' \
	--basic --user ${ORG1_API_KEY}:${ORG1_API_SECRET} \
	--data-binary '{}' \
	${API_ENDPOINT}/api/v1/networks/${NETWORK_ID}/nodes/${PEER}/stop

echo
log "Waiting for ${PEER} to stop..."
RESULT=""
while [[ ${RESULT} != "exited" ]]; do
	RESULT=$(curl -s -X GET \
		--header 'Content-Type: application/json' \
		--header 'Accept: application/json' \
		--basic --user ${ORG1_API_KEY}:${ORG1_API_SECRET} \
		${API_ENDPOINT}/api/v1/networks/${NETWORK_ID}/nodes/status | jq -r '.["'${PEER}'"].status')
	sleep 2
done
echo

log "Starting ${PEER}"
curl -s -X POST \
	--header 'Content-Type: application/json' \
	--header 'Accept: application/json' \
	--basic --user ${ORG1_API_KEY}:${ORG1_API_SECRET} \
	--data-binary '{}' \
	${API_ENDPOINT}/api/v1/networks/${NETWORK_ID}/nodes/${PEER}/start

echo
log "Waiting for ${PEER} to start..."
RESULT=""
while [[ ${RESULT} != "running" ]]; do
	RESULT=$(curl -s -X GET \
		--header 'Content-Type: application/json' \
		--header 'Accept: application/json' \
		--basic --user ${ORG1_API_KEY}:${ORG1_API_SECRET} \
		${API_ENDPOINT}/api/v1/networks/${NETWORK_ID}/nodes/status | jq -r '.["'${PEER}'"].status')
	sleep 2
done

printf "\n\n"

log "Update connection profile to include the admin certs of ${ORG1_NAME}\n\n"
export CERT=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' creds/org1admin/msp/signcerts/cert.pem)
export KEY=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' creds/org1admin/msp/keystore/priv.pem)
export ORG=${ORG1_NAME}
export ORG_NUM=org1
node updateAdminCerts.js

### If this is not enterprise offerig we see two default orgs for starter
if [ "$IS_ENTERPRISE" != true ]; then
	ORG2_NAME=$(jq -r "[.[] | .key][1]" network.json)
	ORG2_API_KEY=$(jq -r .\"${ORG2_NAME}\".key network.json)
	ORG2_API_SECRET=$(jq -r .\"${ORG2_NAME}\".secret network.json)
	log "Downloading the Connection profile for ${ORG2_NAME}"
	curl -s -X GET --header 'Content-Type: application/json' --header 'Accept: application/json' --basic --user ${ORG2_API_KEY}:${ORG2_API_SECRET} ${API_ENDPOINT}/api/v1/networks/${NETWORK_ID}/connection_profile | jq . >& ${CONNECTION_PROF_DIR}/org2.json
	alert $? "download[ed] the connection profile for Org ${ORG2_NAME}\n"

	ORG2_PEER_NAME=$(jq -r .organizations.\"${ORG2_NAME}\".peers[0] ${CONNECTION_PROF_DIR}/org2.json)

	ORG2_CA_NAME=$(jq -r .organizations.\"${ORG2_NAME}\".certificateAuthorities[0] ${CONNECTION_PROF_DIR}/org2.json)
	ORG2_CA_URL=$(jq -r .certificateAuthorities.\"$ORG2_CA_NAME\".url ${CONNECTION_PROF_DIR}/org2.json | cut -d '/' -f 3)
	ORG2_ENROLL_SECRET=$(jq -r .certificateAuthorities.\"$ORG2_CA_NAME\".registrar[0].enrollSecret ${CONNECTION_PROF_DIR}/org2.json)

	banner "Extract Information from ${ORG2_NAME} Connection profile\n\nORG2_PEER_NAME = ${ORG2_PEER_NAME}\nORG2_CA_URL = ${ORG2_CA_URL}\nORG2_ENROLL_SECRET = ${ORG2_ENROLL_SECRET}\n\n\n"

	# STEP 1.2 - ORG2
	log "Enrolling admin user for ${ORG2_NAME}.\n"
	export FABRIC_CA_CLIENT_HOME=${PWD}/creds/org2admin
	fabric-ca-client enroll --tls.certfiles ${PWD}/cacert.pem -u https://admin:${ORG2_ENROLL_SECRET}@${ORG2_CA_URL} --mspdir ${PWD}/creds/org2admin/msp
	# rename the keyfile
	mv creds/org2admin/msp/keystore/* creds/org2admin/msp/keystore/priv.pem
# upload the cert
BODY2=$(cat <<EOF2
{
 "msp_id": "${ORG2_NAME}",
 "adminCertName": "PeerAdminCert2",
 "adminCertificate": "$(get_pem 2)",
 "peer_names": [
   "${ORG2_PEER_NAME}"
 ],
 "SKIP_CACHE": true
}
EOF2
)
	printf "\n\n"
	log " Uploading admin certificate for ${ORG2_NAME}."
	curl -s -X POST \
		--header 'Content-Type: application/json' \
		--header 'Accept: application/json' \
		--basic --user ${ORG2_API_KEY}:${ORG2_API_SECRET} \
		--data "${BODY2}" \
		${API_ENDPOINT}/api/v1/networks/${NETWORK_ID}/certificates

	# STEP 2.2 - ORG2
	printf "\n"
	log " Restarting Peer(s) of ${ORG1_NAME}."
	PEER="${ORG2_PEER_NAME}"
	log "Stoping ${PEER}"
	curl -s -X POST \
		--header 'Content-Type: application/json' \
		--header 'Accept: application/json' \
		--basic --user ${ORG2_API_KEY}:${ORG2_API_SECRET} \
		--data-binary '{}' \
		${API_ENDPOINT}/api/v1/networks/${NETWORK_ID}/nodes/${PEER}/stop
	echo
	log "Waiting for ${PEER} to stop..."
	RESULT=""
	while [[ $RESULT != "exited" ]]; do
		RESULT=$(curl -s -X GET \
			--header 'Content-Type: application/json' \
			--header 'Accept: application/json' \
			--basic --user ${ORG2_API_KEY}:${ORG2_API_SECRET} \
			${API_ENDPOINT}/api/v1/networks/${NETWORK_ID}/nodes/status | jq -r '.["'${PEER}'"].status')
		sleep 2
	done
	echo

	log "Starting ${PEER}"
	curl -s -X POST \
		--header 'Content-Type: application/json' \
		--header 'Accept: application/json' \
		--basic --user ${ORG2_API_KEY}:${ORG2_API_SECRET} \
		--data-binary '{}' \
		${API_ENDPOINT}/api/v1/networks/${NETWORK_ID}/nodes/${PEER}/start
	echo
	log "Waiting for ${PEER} to start..."
	RESULT=""
	while [[ $RESULT != "running" ]]; do
		RESULT=$(curl -s -X GET \
			--header 'Content-Type: application/json' \
			--header 'Accept: application/json' \
			--basic --user ${ORG2_API_KEY}:${ORG2_API_SECRET} \
			${API_ENDPOINT}/api/v1/networks/${NETWORK_ID}/nodes/status | jq -r '.["'${PEER}'"].status')
		sleep 2
	done
	printf "\n\n"
	log "Update connection profiles to include the admin certs of ${ORG2_NAME}"
	export CERT=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' creds/org2admin/msp/signcerts/cert.pem)
	export KEY=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' creds/org2admin/msp/keystore/priv.pem)
	export ORG=${ORG2_NAME}
	export ORG_NUM=org2
	node updateAdminCerts.js
fi

printf "\n"

#########################
# STEP 3 - SYNC CHANNEL #
#########################
log "Syncing the channel."
curl -s -X POST \
	--header 'Content-Type: application/json' \
  	--header 'Accept: application/json' \
  	--basic --user ${ORG1_API_KEY}:${ORG1_API_SECRET} \
  	--data-binary '{}' \
  	${API_ENDPOINT}/api/v1/networks/${NETWORK_ID}/channels/${CHANNEL_NAME}/sync

printf "\n\n"

log "===== A D M I N   C E R T S   A R E   S Y N C E D  O N   C H A N N E L ${CHANNEL_NAME} =====\n"
