package client

import (
	"fmt"
	"net/http"
	"time"
	"strings"
	"os/exec"
	"io/ioutil"
	"log"

	"github.com/hyperledger/fabric-test/tools/operator/connectionprofile"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	// k8s "k8s.io/client-go/kubernetes"
)

//CheckComponentsHealth -- to check the health of a peer or an orderer
func CheckComponentsHealth(componentName, kubeconfigPath string, input networkspec.Config) error {

	if componentName != ""{
		_ = checkHealth(componentName, kubeconfigPath, input)
	} else {
		for i := 0; i < len(input.OrdererOrganizations); i++ {
			org := input.OrdererOrganizations[i]
			for j := 0; j < org.NumOrderers; j++ {
				ordererName := fmt.Sprintf("orderer%v-%v", j, org.Name)
				_ = checkHealth(ordererName, kubeconfigPath, input)
			}
		}

		for i := 0; i < len(input.PeerOrganizations); i++ {
			org := input.PeerOrganizations[i]
			for j := 0; j < org.NumPeers; j++ {
				peerName := fmt.Sprintf("peer%v-%v", j, org.Name)
				_ = checkHealth(peerName, kubeconfigPath, input)
			}
		}
	}

	return nil
}

func CheckDockerHealth(){
	url := fmt.Sprintf("http://%v:%v/healthz", localhost, 31000)
	fmt.Println(url)
	resp, err := http.Get(url)
	if err != nil {
		log.Fatalf("Error while hitting the endpoint, err: %v", err)
	}
	defer resp.Body.Close()
	var healthStatus string
	if resp.StatusCode == http.StatusOK {
		bodyBytes, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			log.Fatal(err)
		}
		healthStatus = string(bodyBytes)
	}
}
func checkHealth(componentName, kubeconfigPath string, input networkspec.Config) bool {

	fmt.Println("Checking health for", componentName)
	portNumber, err := connectionprofile.GetK8sServicePort(kubeconfigPath, componentName, true)
	if err != nil {
		fmt.Errorf("%v", err)
	}
	NodeIP, err := connectionprofile.GetK8sExternalIP(kubeconfigPath, input, componentName)
	if err != nil {
		fmt.Errorf("%v", err)
	}

	url := fmt.Sprintf("http://%v:%v/healthz", NodeIP, portNumber)
	fmt.Println(url)
	resp, err := http.Get(url)
	if err != nil {
		log.Fatalf("Error while hitting the endpoint, err: %v", err)
	}
	defer resp.Body.Close()
	var healthStatus string
	if resp.StatusCode == http.StatusOK {
		bodyBytes, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			log.Fatal(err)
		}
		healthStatus = string(bodyBytes)
	}
	fmt.Println("Status of", componentName, " health: ", healthStatus)
	return false
}

//CheckContainersState -- Checks whether the pod is running or not
func CheckContainersState(componentName, kubeconfigPath string, input networkspec.Config) error{

	var status string

	for i:=0; i<10; i++{
		if status == "No resources found."{
			return nil
		}
		stdoutStderr, err := exec.Command("kubectl", fmt.Sprintf("--kubeconfig=%v", kubeconfigPath), "get", "pods", "--field-selector=status.phase!=Running").CombinedOutput()
		if err != nil{
			fmt.Println("Error occured while executing the commad \n", string(stdoutStderr))
		}
		status = strings.TrimSpace(string(stdoutStderr))
		if status=="No resources found."{
			fmt.Println("All pods are up and running")
			return nil
		}
		fmt.Println("Waiting for the pods to up and running")
		time.Sleep(60 * time.Second)
		if i >= 10{
			return fmt.Errorf("Waiting time exceeded")
		}
	}
	return nil
}