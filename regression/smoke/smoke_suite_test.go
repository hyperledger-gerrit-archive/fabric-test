package smoke_test

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/ginkgo/reporters"

	"github.com/hyperledger/fabric-test/tools/operator/launcher"
)

func TestSmoke(t *testing.T) {
	RegisterFailHandler(Fail)
	junitReporter := reporters.NewJUnitReporter("junit.xml")
    RunSpecsWithDefaultAndCustomReporters(t, "Smoke Suite", []Reporter{junitReporter})
	//RunSpecs(t, "Smoke Suite")
}

var _ = BeforeSuite(func() {
	networkSpecPath := "./networkspec.yaml"
	err := launcher.Launcher("down", "docker", "", networkSpecPath)
	err = launcher.Launcher("up", "docker", "", networkSpecPath)
	Expect(err).NotTo(HaveOccurred())
})

var _ = AfterSuite(func(){
	networkSpecPath := "./networkspec.yaml"
	err := launcher.Launcher("down", "docker", "", networkSpecPath)
	Expect(err).NotTo(HaveOccurred())
})