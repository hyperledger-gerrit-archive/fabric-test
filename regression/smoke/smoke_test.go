package smoke_test

import (
	. "github.com/onsi/ginkgo"
//	. "github.com/onsi/gomega"
	
	"github.com/hyperledger/fabric-test/tools/operator/testclient"
)

var _ = Describe("Smoke Test", func() {

	Describe("Create channel and Joining peers to channel", func() {
		var (
			action string
			inputSpecPath string
		)

		BeforeEach(func(){
			inputSpecPath = "./pte-input.yml"
            
		})
		
		//AfterEach()
        It("Running end to end", func() {
			inputSpecPath = "./pte-input.yml"
			
			By("1) Creating channel")
			action = "create"
			testclient.Testclient(action, inputSpecPath)

			By("2) Joining Peers to channel")
			action = "join"
			testclient.Testclient(action, inputSpecPath)

			By("3) Installing Chaincode on Peers")
			action = "install"
			testclient.Testclient(action, inputSpecPath)

			By("4) Instantiating Chaincode")
			action = "instantiate"
			testclient.Testclient(action, inputSpecPath)
        })
	})
})

func verifyOrdererStatus() {
	
}
