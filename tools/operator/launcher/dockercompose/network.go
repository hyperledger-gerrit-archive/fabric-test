package dockercompose


import (
	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
	"github.com/hyperledger/fabric-test/tools/operator/nl"
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

//DockerNetwork --
func (d DockerCompose) DockerNetwork(action string){

	var err error
	var network nl.Network
	switch action{
	case "up":
		err = d.GenerateConfigurationFiles()
		if err != nil{
			log.Fatalf("Failed to generate docker configuration files; err: %s", err)
		}
		err = network.Generate(d.Input)
		if err != nil{
			log.Fatalln(err)
		}
		err = d.LaunchLocalNetwork()
		if err != nil{
			log.Fatalf("Failed to launch docker components; err: %s", err)
		}
		err = d.VerifyContainersAreRunning()
		if err != nil{
			log.Fatalf("Failed to verify docker container state; err: %s", err)
		}
		err = d.CheckDockerContainersHealth(d.Input)
		if err != nil{
			log.Fatalf("Failed to check docker containers health; err: %s", err)
		}
		err = d.GenerateConnectionProfiles(d.Input)
		if err != nil{
			log.Fatalf("Failed to generate connection profile; err: %s", err)
		}
		
	case "down":
		err = d.DownLocalNetwork()
		if err != nil{
			log.Fatalf("Failed to down local fabric network; err: %s", err)
		}
	default:
		log.Fatalf("Incorrect action (%s). Use up or down for action", action)
	}
}