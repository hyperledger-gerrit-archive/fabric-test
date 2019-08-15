package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	yaml "gopkg.in/yaml.v2"
)

type Port struct{
	NodePort string `yaml:"nodePort,omitempty"`
	TargetPort string `yaml:"targetPort,omitempty"`
}
type Config struct {
	Spec struct {
		Ports []Port `yaml:"ports,omitempty"`
	} `yaml:"spec,omitempty"`
}

func ExecuteCommand(name string, args []string, printLogs bool) (string, error) {

	cmd := exec.Command(name, args...)
	var stdBuffer bytes.Buffer
	mw := io.MultiWriter(os.Stdout, &stdBuffer)
	if printLogs {
		cmd.Stdout = mw
		cmd.Stderr = mw
	} else {
		cmd.Stdout = &stdBuffer
		cmd.Stderr = &stdBuffer
	}
	if err := cmd.Run(); err != nil {
		return string(stdBuffer.Bytes()), err
	}
	return strings.TrimSpace(string(stdBuffer.Bytes())), nil
}

func main() {
	args := []string{"get", "-o", "json", "service", "orderer0-ordererorg1"}
	abc, err := ExecuteCommand("kubectl", args, false)
	if err != nil {
		fmt.Printf("%s", err)
	}
	// fmt.Printf("anc is%s", abc)
	var config Config
	err = yaml.Unmarshal([]byte(abc), &config)
	if err != nil {
		fmt.Println("Failed to create config object")
	}
	fmt.Printf("Config is %s", config.Spec.Ports[0].NodePort)
}
