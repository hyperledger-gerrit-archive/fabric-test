package client

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	helper "fabric-test/tools/operator/launcher/helper"
)

//MigrateFromKafkaToRaft -  to migrate from solo or kafka to raft
func MigrateFromKafkaToRaft(networkSpec helper.Config, kubeConfigPath string) error {

	ordererOrgs := []string{}
	numOrderersPerOrg := []string{}
	for j := 0; j < len(networkSpec.OrdererOrganizations); j++ {
		orderer_orgs = append(orderer_orgs, networkSpec.OrdererOrganizations[j].Name)
		num_orderers_per_org = append(num_orderers_per_org, fmt.Sprintf("%v", networkSpec.OrdererOrganizations[j].NumOrderers))
	}
	ordererOrg := strings.Join(orderer_orgs[:], ",")
	numOrderers := strings.Join(num_orderers_per_org[:], ",")
	cmd := exec.Command("./scripts/migrateToRaft.sh", kubeConfigPath, networkSpec.OrdererOrganizations[0].MSPID, networkSpec.ArtifactsLocation, orderer_org, num_orderers, fmt.Sprintf("%v", networkSpec.NumChannels))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		return err
	}
	fmt.Println("Successfully migrated from kafka to etcdraft")
	return nil
}
