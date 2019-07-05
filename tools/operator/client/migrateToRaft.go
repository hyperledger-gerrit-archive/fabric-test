package client

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	helper "github.com/hyperledger/fabric-test/tools/operator/networkspec"
)

//MigrateFromKafkaToRaft -  to migrate from solo or kafka to raft
func MigrateFromKafkaToRaft(networkSpec helper.Config, kubeConfigPath string) error {

	ordererOrgs := []string{}
	numOrderersPerOrg := []string{}
	for j := 0; j < len(networkSpec.OrdererOrganizations); j++ {
		ordererOrgs = append(ordererOrgs, networkSpec.OrdererOrganizations[j].Name)
		numOrderersPerOrg = append(numOrderersPerOrg, fmt.Sprintf("%v", networkSpec.OrdererOrganizations[j].NumOrderers))
	}
	ordererOrg := strings.Join(ordererOrgs[:], ",")
	numOrderers := strings.Join(numOrderersPerOrg[:], ",")
	cmd := exec.Command("./scripts/migrateToRaft.sh", kubeConfigPath, networkSpec.OrdererOrganizations[0].MSPID, networkSpec.ArtifactsLocation, ordererOrg, numOrderers, fmt.Sprintf("%v", networkSpec.NumChannels))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		return err
	}
	fmt.Println("Successfully migrated from kafka to etcdraft")
	return nil
}
