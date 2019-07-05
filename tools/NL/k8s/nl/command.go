package nl

import (
    "fmt"
    "os/exec"
)

func ExecuteCommand(name string, args ...string) error {

    stdoutStderr, err := exec.Command(name, args...).CombinedOutput()
    if err != nil {
        return fmt.Errorf("%v", string(stdoutStderr))
    }
    fmt.Printf(string(stdoutStderr))
    return nil
}