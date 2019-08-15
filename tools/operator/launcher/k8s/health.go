package k8s

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"time"

	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
)

func (k K8s) VerifyContainersAreRunning(kubeconfigPath string) error {

	var status string
	for i := 0; i < 10; i++ {
		if status == "No resources found." {
			return nil
		}
		input := []string{"get", "pods", "--field-selector=status.phase!=Running"}
		k = K8s{KubeConfigPath: kubeconfigPath, Input: input}
		output, err := client.ExecuteK8sCommand(k.Args(), false)
		if err != nil {
			utils.PrintLogs("Error occured while getting the number of containers in running state")
			return err
		}
		status = strings.TrimSpace(string(output))
		if status == "No resources found." {
			utils.PrintLogs("All pods are up and running")
			return nil
		}
		utils.PrintLogs(fmt.Sprintf("Waiting up to 10 minutes for pods to be up and running; minute = %d", i))
		time.Sleep(60 * time.Second)
	}
	return errors.New("Waiting time exceeded")
}

func (k K8s) checkHealth(componentName, input networkspec.Config) error {

	utils.PrintLogs(fmt.Sprintf("Checking health for %s", componentName))
	var NodeIP string
	portNumber, err := connectionprofile.ServicePort(k.kubeconfigPath, componentName, input.K8s.ServiceType, true)
	if err != nil {
		utils.PrintLogs(fmt.Sprintf("Failed to get the port for %s", componentName))
		return err
	}
	NodeIP, err = connectionprofile.ExternalIP(k.kubeconfigPath, input, componentName)
	if err != nil {
		utils.PrintLogs(fmt.Sprintf("Failed to get the IP address for %s", componentName))
		return err
	}

	url := fmt.Sprintf("http://%s:%s/healthz", NodeIP, portNumber)
	resp, err := http.Get(url)
	if err != nil {
		utils.PrintLogs("Error while hitting the endpoint")
		return err
	}
	defer resp.Body.Close()
	var healthStatus string
	if resp.StatusCode == 200 || resp.StatusCode == 503 {
		bodyBytes, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return err
		}
		healthStatus = string(bodyBytes)
	}
	utils.PrintLogs(fmt.Sprintf("Status of %s health: %s", componentName, healthStatus))
	return nil
}

func (k K8s) CheckK8sComponentsHealth(input networkspec.Config, kubeconfigPath string) error {

	k.KubeConfigPath = kubeconfigPath
	var err error
	time.Sleep(15 * time.Second)
	for i := 0; i < len(input.OrdererOrganizations); i++ {
		org := input.OrdererOrganizations[i]
		for j := 0; j < org.NumOrderers; j++ {
			ordererName := fmt.Sprintf("orderer%d-%s", j, org.Name)
			err = k.checkHealth(ordererName, input)
			if err != nil {
				return err
			}
		}
	}

	for i := 0; i < len(input.PeerOrganizations); i++ {
		org := input.PeerOrganizations[i]
		for j := 0; j < org.NumPeers; j++ {
			peerName := fmt.Sprintf("peer%d-%s", j, org.Name)
			err = k.checkHealth(peerName, input)
			if err != nil {
				return err
			}
		}
	}

	return nil
}
