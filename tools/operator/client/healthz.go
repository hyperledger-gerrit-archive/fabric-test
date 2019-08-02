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

func checkHealth(componentName, kubeconfigPath string, input networkspec.Config) bool {

	fmt.Println("Checking health for", componentName)
	var NodeIP string
	portNumber, err := connectionprofile.GetK8sServicePort(kubeconfigPath, componentName, true)
	if err != nil {
		fmt.Errorf("%v", err)
	}
	if kubeconfigPath != ""{
		NodeIP, err = connectionprofile.GetK8sExternalIP(kubeconfigPath, input, componentName)
		if err != nil {
			fmt.Errorf("%v", err)
		}
	} else{
		stdoutStderr, err := exec.Command("curl", "api.ipify.org").CombinedOutput()
		if err != nil{
			fmt.Println("Error occured while retrieving the local IP \n", string(stdoutStderr))
		}
		IPArr := strings.Split(string(stdoutStderr), "\n")
		NodeIP = IPArr[len(IPArr)-1]
	}

	url := fmt.Sprintf("http://%v:%v/healthz", NodeIP, portNumber)
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
func CheckContainersState(kubeconfigPath string) error{

	fmt.Println("Checking the state of all the containers")
	var err error
	if kubeconfigPath != ""{
		err = checkK8sContainerState(kubeconfigPath)
		if err != nil{
			return err
		}
	}else {
		err = checkDockerContainerState()
		if err != nil{
			return err
		}
	}
	return nil
}

func checkK8sContainerState(kubeconfigPath string) error{

	var status string
	for i:=0; i<10; i++{
		if status == "No resources found."{
			return nil
		}
		stdoutStderr, err := exec.Command("kubectl", fmt.Sprintf("--kubeconfig=%v", kubeconfigPath), "get", "pods", "--field-selector=status.phase!=Running").CombinedOutput()
		if err != nil{
			fmt.Println("Error occured while getting the number of containers in running state \n", string(stdoutStderr))
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

func checkDockerContainerState() error{

	stdoutStderr, err := exec.Command("docker", "ps", "-a").CombinedOutput()
	if err != nil{
		fmt.Println("Error occured while listing all the containers \n", string(stdoutStderr))
	}
	numContainers := string(stdoutStderr)
	stdoutStderr, err = exec.Command("docker", "ps", "-af", "status=running").CombinedOutput()
	if err != nil{
		fmt.Println("Error occured while listing the running containers \n", string(stdoutStderr))
	}
	runningContainers := fmt.Sprintf("%v", len(strings.Split(string(stdoutStderr), "\n")))

	for i:=0; i<2; i++{
		if numContainers == runningContainers{
			return nil
		}
		stdoutStderr, err = exec.Command("docker", "ps", "-af", "status=exited").CombinedOutput()
		if err != nil{
			fmt.Println("Error occured while listing the exited containers \n", string(stdoutStderr))
		}
		exitedContainers := len(strings.Split(strings.TrimSpace(string(stdoutStderr)), "\n"))
		if exitedContainers > 1{
			return fmt.Errorf("Containers exited")
		}
		time.Sleep(10 * time.Second)
		if i >= 10{
			return fmt.Errorf("Waiting time exceeded")
		}
	}
	return nil
}