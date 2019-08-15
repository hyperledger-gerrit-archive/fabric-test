package dockercompose

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"time"
	"log"

	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
)

func (d DockerCompose) VerifyContainersAreRunning() error {

	args := []string{"ps", "-a"}
	output, err := client.ExecuteCommand("docker", args, false)
	if err != nil {
		log.Println("Error occured while listing all the containers")
		return err
	}
	numContainers := fmt.Sprintf("%d", len(strings.Split(string(output), "\n")))
	for i := 0; i < 6; i++ {
		args = []string{"ps", "-af", "status=running"}
		output, err = client.ExecuteCommand("docker", args, false)
		if err != nil {
			log.Println("Error occured while listing the running containers")
			return err
		}
		runningContainers := fmt.Sprintf("%d", len(strings.Split(string(output), "\n")))
		if numContainers == runningContainers {
			log.Println("All the containers are up and running")
			return nil
		}
		args = []string{"ps", "-af", "status=exited"}
		output, err = client.ExecuteCommand("docker", args, false)
		if err != nil {
			log.Println("Error occured while listing the exited containers")
			return err
		}
		exitedContainers := len(strings.Split(strings.TrimSpace(string(output)), "\n"))
		if exitedContainers > 1 {
			return errors.New("Containers exited")
		}
		time.Sleep(10 * time.Second)
	}
	return errors.New("Waiting time to bring up containers exceeded 1 minute")
}

func (d DockerCompose) checkHealth(componentName string, input networkspec.Config) error {

	log.Printf("Checking health for %s", componentName)
	var NodeIP string
	portNumber, err := d.DockerServicePort(componentName, true)
	if err != nil {
		log.Printf("Failed to get the port for %s", componentName)
		return err
	}
	output, err := client.ExecuteCommand("curl", []string{"api.ipify.org"}, false)
	if err != nil {
		log.Println("Error occured while retrieving the local IP")
		return err
	}
	IPArr := strings.Split(string(output), "\n")
	NodeIP = IPArr[len(IPArr)-1]

	url := fmt.Sprintf("http://%s:%s/healthz", NodeIP, portNumber)
	resp, err := http.Get(url)
	if err != nil {
		log.Println("Error while hitting the endpoint")
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
	log.Printf("Status of %s health: %s", componentName, healthStatus)
	return nil
}

func (d DockerCompose) CheckDockerContainersHealth(input networkspec.Config) error {

	var err error
	time.Sleep(15 * time.Second)
	for i := 0; i < len(input.OrdererOrganizations); i++ {
		org := input.OrdererOrganizations[i]
		for j := 0; j < org.NumOrderers; j++ {
			ordererName := fmt.Sprintf("orderer%d-%s", j, org.Name)
			err = d.checkHealth(ordererName, input)
			if err != nil {
				return err
			}
		}
	}

	for i := 0; i < len(input.PeerOrganizations); i++ {
		org := input.PeerOrganizations[i]
		for j := 0; j < org.NumPeers; j++ {
			peerName := fmt.Sprintf("peer%d-%s", j, org.Name)
			err = d.checkHealth(peerName, input)
			if err != nil {
				return err
			}
		}
	}

	return nil
}
