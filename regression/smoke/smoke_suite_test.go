package smoke_test

import (
	"testing"
	"strings"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/ginkgo/reporters"

	"github.com/hyperledger/fabric-test/tools/operator/launcher"
	"github.com/hyperledger/fabric-test/tools/operator/networkclient"
)

func TestSmoke(t *testing.T) {
	RegisterFailHandler(Fail)
	junitReporter := reporters.NewJUnitReporter("junit.xml")
	RunSpecsWithDefaultAndCustomReporters(t, "Smoke Suite", []Reporter{junitReporter})
}

var _ = BeforeSuite(func() {
	networkSpecPath := "./networkspec.yaml"
	err := launcher.Launcher("up", "docker", "", networkSpecPath)
	Expect(err).NotTo(HaveOccurred())
})

var _ = AfterSuite(func(){
	networkSpecPath := "./networkspec.yaml"
	err := launcher.Launcher("down", "docker", "", networkSpecPath)
	Expect(err).NotTo(HaveOccurred())

	dockerList := []string{"ps", "-aq", "-f", "status=exited"};
	containerList, _ := networkclient.ExecuteCommand("docker", dockerList, false);
	if containerList != "" {
		list := strings.Split(containerList, "\n")
		containerArgs := []string{"rm", "-f"}
		containerArgs = append(containerArgs, list...)
		networkclient.ExecuteCommand("docker", containerArgs, true);
	}
	ccimagesList := []string{"images", "-q", "--filter=reference=dev*"}
	images, _ := networkclient.ExecuteCommand("docker", ccimagesList, false);
	if images != "" {
		list := strings.Split(images, "\n")
		imageArgs := []string{"rmi", "-f"}
		imageArgs = append(imageArgs, list...)
		networkclient.ExecuteCommand("docker", imageArgs, true);
	}
})
