package k8s

import (
	"fmt"

	"github.com/hyperledger/fabric-test/tools/operator/logger"
	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/launcher/nl"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
)

type K8s struct {
	KubeConfigPath string
	Action         string
	Arguments      []string
	Input 		   networkspec.Config
}

func (k K8s) Args() []string {

	kubeConfigPath := fmt.Sprintf("--kubeconfig=%s", k.KubeConfigPath)
	args := []string{kubeConfigPath}
	if k.Action != "" {
		args = append(args, k.Action)
	}
	for i := 0; i < len(k.Arguments); i++ {
		switch k.Action {
		case "apply", "delete":
			args = append(args, []string{"-f", k.Arguments[i]}...)
		default:
			args = append(args, k.Arguments[i])
		}
	}
	return args
}

func (k K8s) ConfigMapsNSecretsArgs(componentName, k8sType string) []string {

	kubeConfigPath := fmt.Sprintf("--kubeconfig=%s", k.KubeConfigPath)
	args := []string{kubeConfigPath, k.Action, k8sType}
	if k8sType == "secret" {
		args = append(args, "generic")
	}
	args = append(args, componentName)
	for i := 0; i < len(k.Arguments); i++ {
		switch k.Action {
		case "create":
			args = append(args, fmt.Sprintf("--from-file=%s", k.Arguments[i]))
		default:
			args = append(args, k.Arguments[i])
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
func (k K8s) LaunchK8sNetwork(input networkspec.Config, kubeConfigPath string) error {

	path := utils.ChannelArtifactsDir(input.ArtifactsLocation)\
	inputArgs := []string{utils.JoinPath(path, "genesis.block")}
	k = K8s{KubeConfigPath: kubeConfigPath, Action: "create", Arguments: inputArgs}
	_, err := client.ExecuteK8sCommand(k.ConfigMapsNSecretsArgs("genesisblock", "secret"), true)
	if err != nil {
		return err
	}
	k8sServicesFile := utils.ConfigFilePath("services")
	k8sPodsFile := utils.ConfigFilePath("pods")
	inputPaths := []string{k8sServicesFile, k8sPodsFile}
	if input.K8s.DataPersistence == "true" {
		k8sPvcFile := utils.ConfigFilePath("pvc")
		inputPaths = append(inputPaths, k8sPvcFile)
	}
	k = K8s{Action: "apply", Arguments: inputPaths, KubeConfigPath: kubeConfigPath}
	_, err = client.ExecuteK8sCommand(k.Args(), true)
	if err != nil {
		logger.INFO("Failed to launch the fabric k8s components")
		return err
	}
	return nil
}

//DownK8sNetwork - To tear down the kubernates network
func (k K8s) DownK8sNetwork(kubeConfigPath string, input networkspec.Config) error {

	var err error
	var numComponents int
	var network nl.Network
	secrets := []string{"genesisblock"}
	k.KubeConfigPath = kubeConfigPath
	numOrdererOrganizations := len(input.OrdererOrganizations)
	for i := 0; i < numOrdererOrganizations; i++ {
		ordererOrg := input.OrdererOrganizations[i]
		numComponents = ordererOrg.NumOrderers
		err = k.deleteConfigMaps(numComponents, "orderer", ordererOrg.Name, input.TLS, "configmaps")
		if err != nil {
			logger.INFO("Failed to delete orderer configmaps in ", ordererOrg.Name)
		}
		if input.TLS == "mutual" {
			secrets = append(secrets, fmt.Sprintf("%s-clientrootca-secret", ordererOrg.Name))
		}
	}

	for i := 0; i < len(input.PeerOrganizations); i++ {
		peerOrg := input.PeerOrganizations[i]
		numComponents = peerOrg.NumPeers
		err = k.deleteConfigMaps(numComponents, "peer", peerOrg.Name, input.TLS, "configmaps")
		if err != nil {
			logger.INFO("Failed to delete peer secrets in %s", peerOrg.Name)
		}
		if input.TLS == "mutual" {
			secrets = append(secrets, fmt.Sprintf("%s-clientrootca-secret", peerOrg.Name))
		}
	}
	k8sServicesFile := utils.ConfigFilePath("services")
	k8sPodsFile := utils.ConfigFilePath("pods")

	var inputPaths []string
	if input.K8s.DataPersistence == "local" {
		inputPaths = []string{k.dataPersistenceFilePath(input)}
		k = K8s{KubeConfigPath: kubeConfigPath, Action: "apply", Arguments: inputPaths}
		_, err = client.ExecuteK8sCommand(k.Args(), true)
		if err != nil {
			logger.INFO("Failed to launch k8s pod")
		}
	}
	inputPaths = []string{k8sServicesFile, k8sPodsFile}
	if input.K8s.DataPersistence == "true" || input.K8s.DataPersistence == "local" {
		inputPaths = append(inputPaths, k.dataPersistenceFilePath(input))
	}

	k = K8s{KubeConfigPath: kubeConfigPath, Action: "delete", Arguments: inputPaths}
	_, err = client.ExecuteK8sCommand(k.Args(), true)
	if err != nil {
		logger.INFO("Failed to down k8s components")
	}

	inputArgs := []string{"delete", "secrets"}
	inputArgs = append(inputArgs, secrets...)
	k = K8s{KubeConfigPath: kubeConfigPath, Arguments: inputArgs}
	_, err = client.ExecuteK8sCommand(k.Args(), true)
	if err != nil {
		logger.INFO("Failed to delete secrets")
	}
	err = network.NetworkCleanUp(input)
	if err != nil{
		return err
	}
	return nil
}

func (k K8s) dataPersistenceFilePath(input networkspec.Config) string {

	var path string
	currDir, err := utils.GetCurrentDir()
	if err != nil {
		logger.INFO("Failed to get the current working directory")
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
	k.Arguments = input
	_, err := client.ExecuteK8sCommand(k.Args(), true)
	if err != nil {
		return err
	}
	return nil
}

func (k K8s) K8sNetwork(action string, input networkspec.Config) error{

	var err error
	var network nl.Network
	switch action{
	case "up":
		err = k.GenerateConfigurationFiles()
		if err != nil{
			logger.INFO("Failed to generate k8s configuration files")
			return err
		}
		err = network.Generate(input)
		if err != nil{
			logger.ERROR(err)
		}
		err = k.CreateMSPConfigMaps(input, k.KubeConfigPath)
		if err != nil{
			logger.ERROR(err, "Failed to create config maps")
		}
		err = k.LaunchK8sNetwork(input, k.KubeConfigPath)
		if err != nil{
			logger.ERROR(err, "Failed to launch k8s components")
		}
		err = k.VerifyContainersAreRunning()
		if err != nil{
			logger.ERROR(err, "Failed to verify docker container state")
		}
		err = k.CheckK8sComponentsHealth(input, k.KubeConfigPath)
		if err != nil{
			logger.ERROR(err, "Failed to check docker containers health")
		}
		err = k.GenerateConnectionProfiles(input)
		if err != nil{
			logger.ERROR(err, "Failed to generate connection profile")
		}
	
	case "down":
		err = k.DownK8sNetwork(k.KubeConfigPath, input)
		if err != nil{
			logger.ERROR(err, "Failed to down local fabric network")
		}
	default:
		logger.ERROR(nil, "Incorrect action", action, "Use up or down for action")
	}
	return nil
}