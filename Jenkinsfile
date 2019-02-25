// Copyright IBM Corp All Rights Reserved
//
// SPDX-License-Identifier: Apache-2.0
//
pipeline {
timeout(60) {
agent { node { label ('hyp-x') } } { // trigger build on x86_64 node
 timestamps {
    try {
     def ROOTDIR = pwd() // workspace dir (/w/workspace/<job_name>)
     def nodeHome = tool 'nodejs-8.11.3'
     env.GO_VER = sh(returnStdout: true, script: 'curl -O https://raw.githubusercontent.com/hyperledger/fabric/master/ci.properties && cat ci.properties | grep "GO_VER" | cut -d "=" -f2').trim()
     env.ARCH = "amd64"
     env.PROJECT_DIR = "gopath/src/github.com/hyperledger"
     env.GOROOT = "/opt/go/go${GO_VER}.linux.${ARCH}"
     env.GOPATH = "$WORKSPACE/gopath"
     env.PATH = "$GOPATH/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:${nodeHome}/bin:$GOROOT/bin:$GOPATH/src/github.com/hyperledger/fabric/.build/bin:$PATH"
     def jobname = sh(returnStdout: true, script: 'echo ${JOB_NAME} | grep -q "verify" && echo patchset || echo merge').trim()
     def failure_stage = "none"
      stage("Fetch Patchset") {
          try {
             if (jobname == "patchset")  {
                   println "$GERRIT_REFSPEC"
                   println "$GERRIT_BRANCH"
                   checkout([
                       $class: 'GitSCM',
                       branches: [[name: '$GERRIT_REFSPEC']],
                       extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: '$BASE_DIR'], [$class: 'CheckoutOption', timeout: 10]],
                       userRemoteConfigs: [[credentialsId: 'hyperledger-jobbuilder', name: 'origin', refspec: '$GERRIT_REFSPEC:$GERRIT_REFSPEC', url: '$GIT_BASE']]])
              } else {
                   // Clone the latest fabric-test commit in merge
                   println "Clone $PROJECT repository"
                   checkout([
                       $class: 'GitSCM',
                       branches: [[name: 'refs/heads/$GERRIT_BRANCH']],
                       extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: '$BASE_DIR']],
                       userRemoteConfigs: [[credentialsId: 'hyperledger-jobbuilder', name: 'origin', refspec: '+refs/heads/$GERRIT_BRANCH:refs/remotes/origin/$GERRIT_BRANCH', url: '$GIT_BASE']]])
              }
              dir("${ROOTDIR}/$PROJECT_DIR/$PROJECT") {
              sh 'make git-log'
              }
          }
          catch (err) {
                 failure_stage = "Fetch patchset"
                 throw err
          }
       }
// clean environment and get env data
      stage("Clean Environment - Get Env Info") {
          wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
           try {
                 dir("${ROOTDIR}/$PROJECT_DIR/fabric-test") {
                 sh 'make jenkins-clean clean jenkins-info'
                 }
               }
           catch (err) {
                 failure_stage = "Clean Environment - Get Env Info"
                 throw err
           }
          }
         }

// Setup working environment
      stage("Setup Environment") {
         wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
           try {
                 dir("${ROOTDIR}/$PROJECT_DIR/fabric-test") {
                 sh 'make pre-req'
                 }
               }
           catch (err) {
                 failure_stage = "Setup Environment"
                 currentBuild.result = 'FAILURE'
                 throw err
           }
         }
      }

// Pull the fabric, thiridparty docker images
      stage("Pull Docker Images") {
         wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
           try {
                 dir("${ROOTDIR}/$PROJECT_DIR/fabric-test") {
                 sh 'make pull-images pull-thirdparty-images'
                 }
               }
           catch (err) {
                 failure_stage = "Pull Docker Images"
                 currentBuild.result = 'FAILURE'
                 throw err
           }
         }
      }

// Pull Binaries
      stage("Pull Binaries") {
         wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
           try {
                 dir("${ROOTDIR}/$PROJECT_DIR/fabric-test") {
                 sh 'make pull-binaries'
                 }
               }
           catch (err) {
                 failure_stage = "Pull Binaries"
                 currentBuild.result = 'FAILURE'
                 throw err
           }
         }
      }

// Build Tooling
      stage("Build Tooling") {
         wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
           try {
                 dir("${ROOTDIR}/$PROJECT_DIR/fabric-test") {
                 sh 'make build-sdk-wrapper'
                 }
               }
           catch (err) {
                 failure_stage = "Build Tooling"
                 currentBuild.result = 'FAILURE'
                 throw err
           }
         }
      }

// Execute Smoke Tests
      stage("Execute Smoke Tests") {
         wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
           try {
                 dir("${ROOTDIR}/$PROJECT_DIR/fabric-test") {
                 sh 'make smoke-tests'
                 }
               }
           catch (err) {
                 failure_stage = "Execute Smoke Tests"
                 currentBuild.result = 'FAILURE'
                 throw err
           }
         }
      }

    } finally { // Archive the build artifacts
           archiveArtifacts allowEmptyArchive: true, artifacts: '**/*.log'
           junit allowEmptyResults: true, testResults: '**/*.xml'
           if (env.JOB_NAME == "fabric-test-merge-x86_64") {
              if (currentBuild.result == 'FAILURE') { // Other values: SUCCESS, UNSTABLE
               // Sends merge failure notifications to Jenkins-robot RocketChat Channel
               rocketSend message: "Build Notification - STATUS: *${currentBuild.result}* - BRANCH: *${env.GERRIT_BRANCH}* - PROJECT: *${env.PROJECT}* - BUILD_URL:  (<${env.BUILD_URL}|Open>)"
              }
           }
      } // finally block
  } // timestamps block
} // node block block
} // timeout block
} // node
} // pipeline

