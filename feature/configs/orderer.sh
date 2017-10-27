sleep 10
# Enroll as CA admin first (Equivalent to login)
fabric-ca-client enroll -d --enrollment.profile tls -u ${CA_ADMIN_ENROLLMENT_URL}

# Save the resulting certificates for the admin user
mkdir -p /var/hyperledger/example.com/configs/users/example.com-admin@example.com
cp -r /var/hyperledger/orderer/msp /var/hyperledger/configs/example.com/users/example.com-admin@example.com/msp
mkdir /var/hyperledger/msp/admincerts
cp /var/hyperledger/orderer/msp/signcerts/* /var/hyperledger/msp/admincerts/admin.pem

# Grab the certificates for the organization
fabric-ca-client getcacert -d -u https://ca.example.com:7054 -M /var/hyperledger/configs/example.com/msp

# Register and enroll the orderer user for the orderer organization
fabric-ca-client register --id.name ${BOOTSTRAP_USER} --id.secret ${BOOTSTRAP_PASS}
fabric-ca-client enroll -d --enrollment.profile tls -u ${ENROLLMENT_URL} -M /var/hyperledger/tls --csr.hosts ${ORDERER_HOST}
fabric-ca-client enroll -d -u ${ENROLLMENT_URL} -M ${ORDERER_GENERAL_LOCALMSPDIR} --enrollment.profile tls

# Register and enroll the orderer admin for the orderer organization
fabric-ca-client register -d --id.name $ADMIN_USER --id.secret $ADMIN_PASS --id.attrs "hf.admin=true:ecert"
fabric-ca-client enroll -d --enrollment.profile tls -u https://${ADMIN_USER}:${ADMIN_PASS}@ca.example.com:7054 -M /var/hyperledger/configs/example.com/users/Admin@example.com/tls --csr.hosts ${ORDERER_HOST}
fabric-ca-client enroll -d -u https://${ADMIN_USER}:${ADMIN_PASS}@ca.example.com:7054 -M /var/hyperledger/configs/example.com/users/Admin@example.com/msp --enrollment.profile tls

## Save the resulting certificates for the orderer0 user
#mkdir -p /var/hyperledger/configs/example.com/users/${BOOTSTRAP_USER}
#mkdir -p /var/hyperledger/configs/example.com/users/Admin
##cp -r /var/hyperledger/msp /var/hyperledger/configs/example.com/users/orderer0/msp

#fabric-ca-client getcacert -d -u ${ENROLLMENT_URL} -M /var/hyperledger/configs/example.com/users/${BOOTSTRAP_USER}/msp
#fabric-ca-client getcacert -d -u https://${ADMIN_USER}:${ADMIN_PASS}@ca.example.com:7054 -M /var/hyperledger/configs/example.com/users/Admin/msp
##fabric-ca-client getcacert -d -u ${ENROLLMENT_URL} -M /var/hyperledger/configs/example.com/msp

# Save the config file, keys and certificates for the orderer's use
cp /var/hyperledger/msp/keystore/* ${ORDERER_GENERAL_TLS_PRIVATEKEY}
cp /var/hyperledger/configs/*.pem /var/hyperledger/msp/cacerts/.
cp /var/hyperledger/configs/configtx.yaml /var/hyperledger/msp/config.yaml
cp /var/hyperledger/configs/*.pem /var/hyperledger/orderer/orderer0.example.com/msp/cacerts/.

mkdir -p /var/hyperledger/configs/example.com/orderer.example.com/msp/cacerts/.
cp /var/hyperledger/configs/*.pem /var/hyperledger/configs/example.com/orderer.example.com/msp/cacerts/.
cp /var/hyperledger/orderer/orderer0.example.com/msp/cacerts/*.pem /var/hyperledger/configs/example.com/msp/cacerts/.
cp /var/hyperledger/orderer/orderer0.example.com/msp/admincerts/*.pem /var/hyperledger/configs/example.com/msp/admincerts/.
cp /var/hyperledger/orderer/orderer0.example.com/msp/signcerts/*.pem /var/hyperledger/configs/example.com/msp/signcerts/.

# Start the orderer
orderer

sleep 999999
