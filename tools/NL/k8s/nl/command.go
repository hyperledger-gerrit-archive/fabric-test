// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

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

func ExecuteK8sCommand(kubeConfigPath string, args ...string) error{

    kubeconfig := fmt.Sprintf("--kubeconfig=%v", kubeConfigPath)
    newArgs := []string{kubeconfig}
    newArgs = append(newArgs, args...)
    err := ExecuteCommand("kubectl", newArgs...)
    if err != nil{
        return fmt.Errorf("err: %v", err)
    }
    return nil
}