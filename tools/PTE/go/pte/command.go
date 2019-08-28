package pte

import (
	"os/exec"
	"strings"
	"io"
	"os"
	"bytes"
)

//ExecuteCommand - to execute the cli commands
func ExecuteCommand(name string, args []string, printLogs bool) (string, error) {

	cmd := exec.Command(name, args...)
	var stdBuffer bytes.Buffer
	mw := io.MultiWriter(os.Stdout, &stdBuffer)
	if printLogs{
		cmd.Stdout = mw
		cmd.Stderr = mw
	} else{
		cmd.Stdout = &stdBuffer
		cmd.Stderr = &stdBuffer
	}
	if err := cmd.Run(); err != nil {
		return  string(stdBuffer.Bytes()), err
	}
	return strings.TrimSpace(string(stdBuffer.Bytes())), nil
}