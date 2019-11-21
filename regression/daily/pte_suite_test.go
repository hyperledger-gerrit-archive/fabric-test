package daily_test

import (
	"testing"
	"os"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/ginkgo/reporters"
	"github.com/hyperledger/fabric-test/tools/operator/networkclient"
)

func TestPTEDaily(t *testing.T) {
	RegisterFailHandler(Fail)
	junitReporter := reporters.NewJUnitReporter("results_daily_pte-test-suite.xml")
	RunSpecsWithDefaultAndCustomReporters(t, "Daily PTE Test Suite", []Reporter{junitReporter})
}

var _ = BeforeSuite(func() {
	scenariosDir := "../../tools/PTE/CITest/scenarios"
	err := os.Chdir(scenariosDir)
	Expect(err).NotTo(HaveOccurred())
})

var _ = Describe("PTE Daily Test Suite", func ()  {
	
	Describe("Running performance measurement tests with CouchDB", func ()  {

		It("test_FAB3833_2i_FAB3810_2q", func ()  {
			_, err := networkclient.ExecuteCommand("./FAB-3833-2i.sh", []string{}, true)
			Expect(err).NotTo(HaveOccurred())
		})
		It("test_FAB3832_4i_FAB3834_4q", func ()  {
			_, err := networkclient.ExecuteCommand("./FAB-3832-4i.sh", []string{}, true)
			Expect(err).NotTo(HaveOccurred())
		})
		It("test_FAB6813_4i_marbles_FAB8199_4q_FAB8200_4q_FAB8201_4q", func ()  {
			_, err := networkclient.ExecuteCommand("./FAB-6813-4i.sh", []string{}, true)
			Expect(err).NotTo(HaveOccurred())
		})
	})
})