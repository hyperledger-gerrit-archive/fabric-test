// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package helper

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"runtime"
)

//DownloadYtt - to download ytt
func DownloadYtt() {
	if _, err := os.Stat("ytt"); os.IsNotExist(err) {
		name := runtime.GOOS
		url := fmt.Sprintf("https://github.com/k14s/ytt/releases/download/v0.13.0/ytt-%v-amd64", name)

		resp, err := http.Get(url)
		if err != nil {
			fmt.Println("Error while downloading the ytt, err:", err)
		}
		defer resp.Body.Close()
		ytt, err := os.Create("ytt")

		defer ytt.Close()
		io.Copy(ytt, resp.Body)
		err = os.Chmod("ytt", 0777)
		if err != nil {
			fmt.Println("Failed to change permissions to ytt, err:", err)
		}
	}
}
