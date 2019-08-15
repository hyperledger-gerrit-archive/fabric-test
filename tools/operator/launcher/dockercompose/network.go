package dockercompose


import (
	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
	"github.com/hyperledger/fabric-test/tools/operator/nl"
)

type DockerCompose struct{
	Config string
	Action []string
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
func (d DockerCompose) LaunchLocalNetwork() error {
	err := d.GenerateConfigurationFiles()
	if err != nil{
		return err
	}
	configPath := utils.ConfigFilePath("docker")
	d = DockerCompose{Config: configPath, Action: []string{"up", "-d"}}
	_, err :=  client.ExecuteCommand("docker-compose", d.Args(), true)
	if err != nil {
		return err
	}
	return nil
}

//DownLocalNetwork -- To tear down the local network
func (d DockerCompose) DownLocalNetwork() error {
	configPath := utils.ConfigFilePath("docker")
	d = DockerCompose{Config: configPath, Action: []string{"down"}}
	_, err :=  client.ExecuteCommand("docker-compose", d.Args(), true)
	if err != nil {
		return err
	}
	return nil
}