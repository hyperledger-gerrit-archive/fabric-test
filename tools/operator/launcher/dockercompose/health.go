package dockercompose

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"time"
	"strconv"

	"github.com/hyperledger/fabric-test/tools/operator/logger"
	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
)

func (d DockerCompose) VerifyContainersAreRunning() error {

	args := []string{"ps", "-a"}
	output, err := client.ExecuteCommand("docker", args, false)
	if err != nil {
		logger.INFO("Error occured while listing all the containers")
		return err
	}
	numContainers := fmt.Sprintf("%d", len(strings.Split(string(output), "\n")))
	for i := 0; i < 6; i++ {
		args = []string{"ps", "-af", "status=running"}
		output, err = client.ExecuteCommand("docker", args, false)
		if err != nil {
			logger.INFO("Error occured while listing the running containers")
			return err
		}
		runningContainers := fmt.Sprintf("%d", len(strings.Split(string(output), "\n")))
		if numContainers == runningContainers {
			logger.INFO("All the containers are up and running")
			return nil
		}
		args = []string{"ps", "-af", "status=exited"}
		output, err = client.ExecuteCommand("docker", args, false)
		if err != nil {
			logger.INFO("Error occured while listing the exited containers")
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

	logger.INFO("Checking health for ", componentName)
	var nodeIP string
	portNumber, err := d.DockerServicePort(componentName, true)
	if err != nil {
		logger.INFO("Failed to get the port for ", componentName)
		return err
	}
	nodeIP, err = d.getIPAddress()
	if err != nil {
		logger.INFO("Error occured while retrieving the local IP")
		return err
	}

	url := fmt.Sprintf("http://%s:%s/healthz", nodeIP, portNumber)
	resp, err := http.Get(url)
	if err != nil {
		logger.INFO("Error while hitting the endpoint")
		return err
	}
	defer resp.Body.Close()
	bodyBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	healthStatus := string(bodyBytes)
	logger.INFO("Response status: ", strconv.Itoa(resp.StatusCode))
	logger.INFO("Response body: ", healthStatus)
	if resp.StatusCode == http.StatusOK {
		logger.INFO("Health check passed for ", componentName)
		return nil
	}
	return fmt.Errorf("Health check failed for %s; Response status = %s", componentName, resp.StatusCode)
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

func (d DockerCompose) getIPAddress() (string, error) {

	var IP string
	var err error
	resp, err := http.Get("http://api.ipify.org")
	if err != nil {
		return IP, err
	}
	defer resp.Body.Close()

	bodyBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return IP, err
	}
	IP = string(bodyBytes)
	return IP, err
}