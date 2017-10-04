#!/bin/bash

# setup for automatic login to user@abc.com without interactive password
# from local:
# ssh-keygen -t rsa
# ssh user@abc.com mkdir -p .ssh
# user@abc.com's password:
# cat .ssh/id_rsa.pub | ssh user@abc.com 'cat >> .ssh/authorized_keys'
# user@abc.com's password:
#

tCurr=`date +%s%N | cut -b1-13`
echo "[$0] called at $tCurr"

while getopts ":b:h:" opt; do
  case $opt in
    # parse environment options
    b)
      tStart=$OPTARG
      echo "[$0] tStart: $tStart"
      ;;

    h)
      userHost=$OPTARG
      echo "[$0] userHost: $userHost"
      ;;

     *)
       echo "[$0] unsupported option: $opt"
       ;;

  esac
done

# remote execution
ssh $userHost  << EOF
echo $GOPATH

cd $GOPATH/src/github.com/hyperledger/fabric-test/fabric-sdk-node/test/PTE/CITest/scripts
./test_driver_remote.sh -t marbles-i-TLS -b $tStart &

EOF

exit
#./test_driver_remote.sh -n -p -c samplecc -t FAB-query-TLS
#./test_driver_remote.sh -n -p -c marblescc -t marbles-q-TLS

#./test_driver_remote.sh -t FAB-3989-4i-TLS -b $tStart &
#./test_driver_remote.sh -t marbles-i-TLS -b $tStart &
#cd $GOPATH/src/github.com/hyperledger/fabric-test/fabric-sdk-node/test/PTE
#./pte_mgr.sh sampleccInputs/PTEMgr-constant-i-TLS.txt &

#cd $GOPATH/src/github.com/hyperledger/fabric-test/fabric-sdk-node/test/PTE/CITest/scripts
#./test_driver_remote.sh -t FAB-3989-4i-TLS -b $tStart &
#./test_driver_remote.sh -t marbles-i-TLS -b $tStart &

#./test_driver.sh -t marbles-d-TLS
#./test_driver.sh -n -p -c samplecc -t FAB-query-TLS FAB-3989-4i-TLS
echo "[$0] done ssh test"

exit

