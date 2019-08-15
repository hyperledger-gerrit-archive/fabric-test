package dockercompose


import (
	"github.com/hyperledger/fabric-test/tools/operator/logger"
	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
	"github.com/hyperledger/fabric-test/tools/operator/launcher/nl"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
)

type DockerCompose struct{
	Config string
	Action []string
	Input networkspec.Config
}

func (d DockerCompose) Args() []string {

	args := []string{"-f", d.Config}
	return append(args, d.Action...)
}

//GenerateConfigurationFiles - to generate all the configuration files
func (d DockerCompose) GenerateConfigurationFiles() error {

	network := nl.Network{TemplatesDir: utils.TemplateFilePath("docker")}
	err := network.GenerateConfigurationFiles()
	if err != nil{
		return err
	}
	return nil
}

//LaunchLocalNetwork -- To launch the network in the local environment
func (d DockerCompose) LaunchLocalNetwork(input networkspec.Config) error {

	d.Input = input
	configPath := utils.ConfigFilePath("docker")
	d = DockerCompose{Config: configPath, Action: []string{"up", "-d"}}
	_, err :=  client.ExecuteCommand("docker-compose", d.Args(), true)
	if err != nil {
		return err
	}
	return nil
}

//DownLocalNetwork -- To tear down the local network
func (d DockerCompose) DownLocalNetwork(input networkspec.Config) error {

	var network nl.Network
	d.Input = input
	configPath := utils.ConfigFilePath("docker")
	d = DockerCompose{Config: configPath, Action: []string{"down"}}
	_, err :=  client.ExecuteCommand("docker-compose", d.Args(), true)
	if err != nil {
		return err
	}
	err = network.NetworkCleanUp(input)
	if err != nil{
		return err
	}
	return nil
}

//DockerNetwork --
func (d DockerCompose) DockerNetwork(action string) error{

	var err error
	var network nl.Network
	switch action{
	case "up":
		err = d.GenerateConfigurationFiles()
		if err != nil{
			logger.INFO("Failed to generate docker compose file")
			return err
		}
		err = network.Generate(d.Input)
		if err != nil{
			logger.CRIT(err)
		}
		err = d.LaunchLocalNetwork(d.Input)
		if err != nil{
			logger.CRIT(err, "Failed to launch docker components")
		}
		err = d.VerifyContainersAreRunning()
		if err != nil{
			logger.CRIT(err,"Failed to verify docker container state")
		}
		err = d.CheckDockerContainersHealth(d.Input)
		if err != nil{
			logger.CRIT(err, "Failed to check docker containers health")
		}
		err = d.GenerateConnectionProfiles(d.Input)
		if err != nil{
			logger.CRIT(err, "Failed to generate connection profile")
		}
		
	case "down":
		err = d.DownLocalNetwork(d.Input)
		if err != nil{
			logger.CRIT(err, "Failed to down local fabric network")
		}
	default:
		logger.CRIT(nil, "Incorrect action ", action, "Use up or down for action")
	}
	return nil
}