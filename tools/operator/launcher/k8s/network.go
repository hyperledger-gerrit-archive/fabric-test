package k8s

import (
	"fmt"
	"log"

	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/nl"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
)

type K8s struct {
	KubeConfigPath string
	Action         string
	Input          []string
}

func (k K8s) Args() []string {

	kubeConfigPath = fmt.Sprintf("--kubeconfig=%s", k.KubeConfigPath)
	args := []string{kubeConfigPath}
	if k.Action != "" {
		args = append(args, k.Action)
	}
	for i := 0; i < len(k.Input); i++ {
		switch k.Action {
		case "apply", "delete":
			args = append(args, []string{"-f", k.Input[i]}...)
		default:
			args = append(args, k.Input[i])
		}

	}
	return args
}

func (k K8s) ConfigMapsNSecretsArgs(componentName, k8sType string) []string {

	kubeConfigPath = fmt.Sprintf("--kubeconfig=%s", k.KubeConfigPath)
	args := []string{kubeConfigPath, k.Action, k8sType}
	if k8sType == "secret" {
		args = append(args, "generic")
	}
	args = append(args, componentName)
	for i := 0; i < len(k.Input); i++ {
		switch k.Action {
		case "create":
			args = append(args, fmt.Sprintf("--from-file=%s", k.Input[i]))
		default:
			args = append(args, k.Input[i])
		}

	}
	return args
}

//GenerateConfigurationFiles - to generate all the configuration files
func (k K8s) GenerateConfigurationFiles() error {
	network := nl.Network{TemplatesDir: utils.TemplateFilePath("k8s")}
	err := network.GenerateConfigurationFiles()
	if err != nil{
		return err
	}
	return nil
}

//LaunchK8sNetwork - to launch the kubernates components
func (k K8s) LaunchK8sNetwork(kubeConfigPath string, isDataPersistence string) error {

	err := k.GenerateConfigurationFiles()
	if err != nil{
		return err
	}
	// from network.go file
	inputArgs := []string{utils.JoinPath(path, "genesis.block")}
	k = K8s{KubeConfigPath: kubeConfigPath, Action: "create", Input: inputArgs}
	_, err = client.ExecuteK8sCommand(k.ConfigMapsNSecretsArgs(k.KubeConfigPath, "genesisblock", "secret"), true)
	if err != nil {
		return err
	}
	//
	k8sServicesFile := utils.ConfigFilePath("services")
	k8sPodsFile := utils.ConfigFilePath("pods")
	inputPaths := []string{k8sServicesFile, k8sPodsFile}
	if isDataPersistence == "true" {
		k8sPvcFile := utils.ConfigFilePath("pvc")
		inputPaths = append(inputPaths, k8sPvcFile)
	}
	k8s := K8s{Action: "apply", Input: inputPaths}
	_, err := client.ExecuteK8sCommand(k8s.Args(), true)
	if err != nil {
		log.Println("Failed to launch the fabric k8s components")
		return err
	}
	return nil
}

//DownK8sNetwork - To tear down the kubernates network
func (k K8s) DownK8sNetwork(kubeConfigPath string, input networkspec.Config) error {

	var err error
	var numComponents int
	secrets := []string{"genesisblock"}
	k.KubeConfigPath = kubeConfigPath
	numOrdererOrganizations := len(input.OrdererOrganizations)
	for i := 0; i < numOrdererOrganizations; i++ {
		ordererOrg := input.OrdererOrganizations[i]
		numComponents = ordererOrg.NumOrderers
		err = deleteConfigMaps(numComponents, "orderer", ordererOrg.Name, input.TLS, "configmaps")
		if err != nil {
			log.Printf("Failed to delete orderer configmaps in %s", ordererOrg.Name)
		}
		if input.TLS == "mutual" {
			secrets = append(secrets, fmt.Sprintf("%s-clientrootca-secret", ordererOrg.Name))
		}
	}

	for i := 0; i < len(input.PeerOrganizations); i++ {
		peerOrg := input.PeerOrganizations[i]
		numComponents = peerOrg.NumPeers
		err = deleteConfigMaps(numComponents, "peer", peerOrg.Name, input.TLS, "configmaps")
		if err != nil {
			log.Printf("Failed to delete peer secrets in %s", peerOrg.Name)
		}
		if input.TLS == "mutual" {
			secrets = append(secrets, fmt.Sprintf("%s-clientrootca-secret", peerOrg.Name))
		}
	}
	k8sServicesFile := utils.ConfigFilePath("services")
	k8sPodsFile := utils.ConfigFilePath("pods")

	var inputPaths []string
	if input.K8s.DataPersistence == "local" {
		inputPaths = []string{dataPersistenceFilePath(input)}
		k = K8s{KubeConfigPath: kubeConfigPath, Action: "apply", Input: inputPaths}
		_, err = client.ExecuteK8sCommand(k.Args(), true)
		if err != nil {
			log.Println("Failed to launch k8s pod")
		}
	}
	inputPaths = []string{k8sServicesFile, k8sPodsFile}
	if input.K8s.DataPersistence == "true" || input.K8s.DataPersistence == "local" {
		inputPaths = append(inputPaths, dataPersistenceFilePath(input))
	}

	k = K8s{KubeConfigPath: kubeConfigPath, Action: "delete", Input: inputPaths}
	_, err = client.ExecuteK8sCommand(k8s.Args(), true)
	if err != nil {
		log.Println("Failed to down k8s pods")
	}

	inputArgs := []string{"delete", "secrets"}
	inputArgs = append(inputArgs, secrets...)
	k = K8s{KubeConfigPath: kubeConfigPath, Input: inputPaths}
	_, err = client.ExecuteK8sCommand(k.Args(), true)
	if err != nil {
		log.Println("Failed to delete secrets")
	}
	return nil
}

func (k K8s) dataPersistenceFilePath(input networkspec.Config) string {
	var path string
	currDir, err := utils.GetCurrentDir()
	if err != nil {
		log.Println("Failed to get the current working directory")
	}
	switch input.K8s.DataPersistence {
	case "local":
		path = utils.JoinPath(currDir, "alpine.yaml")
	default:
		path = utils.ConfigFilePath("pvc")
	}
	return path
}

func (k K8s) deleteConfigMaps(numComponents int, componentType, orgName, tls, k8sType string) error {

	componentsList := []string{fmt.Sprintf("%s-ca", orgName)}
	var componentName string
	for j := 0; j < numComponents; j++ {
		componentName = fmt.Sprintf("%s%d-%s", componentType, j, orgName)
		componentsList = append(componentsList, []string{fmt.Sprintf("%s-tls", componentName), fmt.Sprintf("%s-msp", componentName)}...)
	}
	input := []string{"delete", k8sType}
	input = append(input, componentsList...)
	k.Input = input
	_, err := client.ExecuteK8sCommand(k.Args(), true)
	if err != nil {
		return err
	}
	return nil
}

func (k K8s) K8sNetwork(action string){

	var err error
	var network nl.Network
	switch action{
	case "up":
		err = k.GenerateConfigurationFiles()
		if err != nil{
			log.Fatalf("Failed to generate docker configuration files; err: %s", err)
		}
		err = network.Generate(d.Input)
		if err != nil{
			log.Fatalln(err)
		}
		err = k.LaunchK8sNetwork()
		if err != nil{
			log.Fatalf("Failed to launch docker components; err: %s", err)
		}
		err = k.VerifyContainersAreRunning()
		if err != nil{
			log.Fatalf("Failed to verify docker container state; err: %s", err)
		}
		err = k.CheckK8sComponentsHealth(k.Input)
		if err != nil{
			log.Fatalf("Failed to check docker containers health; err: %s", err)
		}
		err = k.GenerateConnectionProfiles(k.Input)
		if err != nil{
			log.Fatalf("Failed to generate connection profile; err: %s", err)
		}
		
	case "down":
		err = k.DownK8sNetwork(k.KubeConfigPath, k.Input)
		if err != nil{
			log.Fatalf("Failed to down local fabric network; err: %s", err)
		}
	default:
		log.Fatalf("Incorrect action (%s). Use up or down for action", action)
	}
}