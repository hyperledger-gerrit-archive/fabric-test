#!/bin/bash -e
set -o pipefail

# Set the working directory
WD=$GOPATH/src/github.com/hyperledger/fabric-test
cd $WD

# Get the arch value
ARCH=$(dpkg --print-architecture)

echo "Fetching binary artifacts from Nexus"

##########################################################
# Pull the fabric and fabric-ca binaries from Nexus
##########################################################
for REPO in fabric fabric-ca; do
    echo "======== PULL $REPO BINARIES ========"
    echo
    # Set Nexus Snapshot URL
    NEXUS_URL=https://nexus.hyperledger.org/content/repositories/snapshots/org/hyperledger/$REPO/hyperledger-$REPO-latest/$ARCH.latest-SNAPSHOT
    # Download the maven-metadata.xml file
    curl $NEXUS_URL/maven-metadata.xml > maven-metadata.xml
    # Set latest tar file to the VERSION
    VERSION=$(grep value maven-metadata.xml | sort -u | cut -d "<" -f2|cut -d ">" -f2)
    # Download tar.gz file and extract it
    curl $NEXUS_URL/hyperledger-$REPO-latest-$VERSION.tar.gz | tar -C ./bin xz 
done

#Set the PATH to the bin directory in order to execute the correct binaries
export PATH=$WD/bin:$PATH

##################
# Show the results
##################
echo "Binaries fetched from Nexus"
echo
ls -l bin/
echo
