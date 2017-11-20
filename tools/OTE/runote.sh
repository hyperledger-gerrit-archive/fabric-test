#!/bin/bash

CWD=$PWD
OTE_DIR=$CWD/../../../fabric/OTE

function printHelp {

   echo "Usage: "
   echo " ./runote.sh [opt] [value] "
   echo "    -t: testcase number, default=FAB-6996"
   echo " "
   echo " example: "
   echo " ./runote.sh -t FAB-6996"
   exit
}

#defaults
TESTCASE="FAB-6996"

while getopts "t:" opt;
do
        case $opt in
                t)
                  TESTCASE=$OPTARG
                ;;
                \?)
                  echo "Invalid option: -$OPTARG" 2>&1
                  printHelp
                ;;
                :)
                  echo "Option -$OPTARG requires an argument." 2>&1
                  printHelp
                ;;
        esac
done


FAB-6996 () {
        cd $CWD/../NL
        ./networkLauncher.sh -o 1 -x 1 -r 1 -p 1 -n 1 -f test -w localhost -S enabled
        cd $OTE_DIR
        # run testcase
        numChannels=1 testcase=Test_FAB6996_30000TX_1ch_1ord_solo docker-compose -f ote-compose.yml up -d
}

FAB-7024 () {
        cd $CWD/../NL
        ./networkLauncher.sh -o 1 -x 1 -r 1 -p 1 -n 1 -f test -w localhost -B 500 -S enabled
        cd $OTE_DIR
        # run testcase
        numChannels=1 testcase=Test_FAB7024_30000TX_1ch_1ord_solo_500batchsize docker-compose -f ote-compose.yml up -d
}

FAB-7026 () {
        cd $CWD/../NL
        ./networkLauncher.sh -o 1 -x 1 -r 1 -p 1 -n 3 -f test -l DEBUG -w localhost -S enabled
        cd $OTE_DIR
        # run testcase
        testcase=Test_FAB7026_30000TX_3ch_1ord_solo docker-compose -f ote-compose.yml up -d
}

FAB-7036 () {
        cd $CWD/../NL
        ./networkLauncher.sh -o 3 -x 1 -r 1 -p 1 -n 1 -k 5 -z 3 -t kafka -f test -w localhost -S enabled
        cd $OTE_DIR
        # run testcase
        numChannels=1 testcase=Test_FAB7036_30000TX_1ch_3ord_5kb docker-compose -f ote-compose.yml up -d
}

FAB-7037 () {
        cd $CWD/../NL
        ./networkLauncher.sh -o 3 -x 1 -r 1 -p 1 -n 1 -k 5 -z 3 -t kafka -f test -w localhost -B 500 -S enabled
        cd $OTE_DIR
        # run testcase
        numChannels=1 testcase=Test_FAB7037_30000TX_1ch_3ord_5kb_500batchsize docker-compose -f ote-compose.yml up -d
}

FAB-7038 () {
        cd $CWD/../NL
        ./networkLauncher.sh -o 12 -x 1 -r 1 -p 1 -n 1 -k 5 -z 3 -t kafka -f test -w localhost -S enabled
        cd $OTE_DIR
        # run testcase
        numChannels=1 testcase=Test_FAB7038_30000TX_1ch_12ord_5kb docker-compose -f ote-compose.yml up -d
}

FAB-7039 () {
        cd $CWD/../NL
        ./networkLauncher.sh -o 12 -x 1 -r 1 -p 1 -n 1 -k 5 -z 3 -t kafka -f test -w localhost -B 500 -S enabled
        cd $OTE_DIR
        # run testcase
        numChannels=1 testcase=Test_FAB7039_30000TX_1ch_12ord_5kb_500batchsize docker-compose -f ote-compose.yml up -d
}

echo "Starting $TESTCASE test with OTE"
cp -R $CWD/../OTE $CWD/../../../fabric/
$TESTCASE
docker logs -f OTE
# Now look for test results logs in ./logs/${testcase}.log
docker-compose -f ote-compose.yml down
cd ../../fabric-test/tools/NL
./networkLauncher.sh -a down
