package utils

import (

	"os"
	"path/filepath"
	"strings"
	"reflect"
	"fmt"

	"github.com/hyperledger/fabric-test/tools/operator/logger"
)

//CryptoConfigDir --
func CryptoConfigDir(artifactsLocation string) string {
	return componentPath(artifactsLocation, "crypto-config")
}

//ChannelArtifactsDir --
func ChannelArtifactsDir(artifactsLocation string) string {
	return componentPath(artifactsLocation, "channel-artifacts")
}

//ConnectionProfilesDir --
func ConnectionProfilesDir(artifactsLocation string) string {
	return componentPath(artifactsLocation, "connection-profile")
}

//OrdererOrgsDir --
func OrdererOrgsDir(artifactsLocation string) string {
	return componentPath(CryptoConfigDir(artifactsLocation), "ordererOrganizations")
}

//PeerOrgsDir --
func PeerOrgsDir(artifactsLocation string) string {
	return componentPath(CryptoConfigDir(artifactsLocation), "peerOrganizations")
}

//YTTPath --
func YTTPath() string {
	currentDir, err := GetCurrentDir()
	if err != nil {
		logger.CRIT(err)
	}
	if strings.Contains(currentDir, "launcher") {
		return componentPath(currentDir, "ytt")
	}
	return componentPath(currentDir, "ytt")
}

//TemplatesDir --
func TemplatesDir() string {
	currentDir, err := GetCurrentDir()
	if err != nil {
		logger.CRIT(err)
	}
	if strings.Contains(currentDir, "launcher") {
		return componentPath(currentDir, "../templates")
	}
	return componentPath(currentDir, "templates")
}

//TemplateFilePath --
func TemplateFilePath(fileName string) string {
	templateFiles := map[string]string{"crypto-config": "crypto-config.yaml", "configtx": "configtx.yaml", "k8s": "k8s", "docker": "docker", "input": "input.yaml"}
	return JoinPath(TemplatesDir(), templateFiles[fileName])
}

//ConfigFilesDir --
func ConfigFilesDir() string {
	currentDir, err := GetCurrentDir()
	if err != nil {
		logger.CRIT(err)
	}
	if strings.Contains(currentDir, "launcher") {
		return componentPath(currentDir, "../configFiles")
	}
	return componentPath(currentDir, "configFiles")
}

func ConfigFilePath(fileName string) string {
	configFiles := map[string]string{
		"crypto-config": "crypto-config.yaml",
		"configtx": "configtx.yaml",
		"docker":   "docker-compose.yaml",
		"services": "fabric-k8s-service.yaml",
		"pods":     "fabric-k8s-pods.yaml",
		"pvc":      "fabric-k8s-pvc.yaml",
	}
	return JoinPath(ConfigFilesDir(), configFiles[fileName])
}

func GetCurrentDir() (string, error) {
	path, err := os.Getwd()
	if err != nil {
		return path, err
	}
	return path, nil
}

func dirExists(dirPath string) (bool, error) {
	_, err := os.Stat(dirPath)
	if err == nil {
		return true, nil
	}
	if os.IsNotExist(err) {
		return false, nil
	}
	return true, err
}

func createDirectory(dirPath string) error {
	err := os.MkdirAll(dirPath, os.ModePerm)
	if err != nil {
		return err
	}
	return nil
}

func componentPath(artifactsLocation, component string) string {
	path := JoinPath(artifactsLocation, component)
	isExists, _ := dirExists(path)
	if isExists {
		return path
	}
	err := createDirectory(path)
	if err != nil {
		logger.CRIT(err)
	}
	return path
}

//JoinPath ---
func JoinPath(oldPath, newPath string) string {
	return filepath.Join(oldPath, newPath)
}

//GetKeysFromMap --
func GetKeysFromMap(newMap interface{}) []string {

	var componentsList []string
	v := reflect.ValueOf(newMap)
	if v.Kind() != reflect.Map {
		logger.INFO("not a map!")
		return nil
	}
	keys := v.MapKeys()
	for i := range keys {
		componentsList = append(componentsList, fmt.Sprintf("%s", keys[i]))
	}
	return componentsList
}
