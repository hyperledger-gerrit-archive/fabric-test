package nl

import (
	"log"
	"os"
	"path/filepath"
	"strings"
)

templateFiles := make[string]string{"crypto-config":"crypto-config.yaml", "configtx":"configtx.yaml", "k8s":"k8s", "docker":"docker", "input":"input"}
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
	return componentPath(artifactsLocation, "conenction-profile")
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
	currentDir, err := getCurrentDir()
	if err != nil {
		log.Fatal(err)
	}
	if strings.Contains(path, "launcher") {
		return componentPath(path, "ytt")
	}
	return componentPath(path, "ytt")
}

//TemplatesDir --
func TemplatesDir() string {
	currentDir, err := getCurrentDir()
	if err != nil {
		log.Fatal(err)
	}
	if strings.Contains(path, "launcher") {
		return componentPath(path, "../templates")
	}
	return componentPath(path, "templates")
}

//TemplateFilePath --
func TemplateFilePath(fileName string) string{
	return JoinPath(TemplatesDir, templateFiles[filepath])
}
//ConfigFilesDir --
func ConfigFilesDir() string {
	currentDir, err := getCurrentDir()
	if err != nil {
		log.Fatal(err)
	}
	if strings.Contains(path, "launcher") {
		return componentPath(path, "../configFiles")
	}
	return componentPath(path, "configFiles")
}

func getCurrentDir() (string, error) {
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

func createDirectory(dirPath, string) error {
	err := os.Mkdir(dirPath, os.ModePerm)
	if err != nil {
		return err
	}
	return nil
}

func componentPath(artifactsLocation, component) string {
	path := JoinPath(artifactsLocation, component)
	isExists := dirExists(path)
	if isExists {
		return path
	}
	err := createDirectory(path)
	if err != nil {
		log.Fatal(err)
	}
	return path
}

//JoinPath ---
func JoinPath(oldPath, newPath string) string {
	return filepath.Join(oldPath, newPath)
}
