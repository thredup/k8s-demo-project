@Library('jenkins-pipeline@arm64') _
pipeline {
  agent none
  options {
    buildDiscarder(logRotator(daysToKeepStr: '30'))
    timestamps()
    ansiColor('xterm')
  }
  stages {
    stage ('Pre-requisits') {
      steps {
        initPipeline(useGithubApi: false, shallowCheckout: false)
      }
    }
    stage('Test and build image') {
      parallel {
        stage ('Test') {
          steps {
            nodejsContainer (nodeVersion: "8.9.0-builder") {
              sh "echo Your tests go here"
            }
          }
        }

        stage ('Build image') {
          environment {
            NPM_TOKEN = credentials("npm-token")
          }
          steps {
            kanikoArm64Container(serviceAccount: 'jenkins') {
              sh "executor \
                  --context=. \
                  ${env.IMAGE_DESTINATION} \
                  --build-arg=NODE_ENV=production \
                  --build-arg=NPM_TOKEN=${env.NPM_TOKEN} \
                  --build-arg=REVISION=${env.GIT_SHA}"
            }
          }
        }
      }
    }

    stage ('Deploy to staging') {
      when {
        anyOf {
          branch 'master'
          expression { BRANCH_NAME ==~ /staging.*/ }
        }
      }
      steps {
        helmContainer() {
          sh "helm upgrade --install \
                           --wait --timeout 60 \
                           -f ./helm/env/staging.yaml \
                           --set image.tag=${env.GIT_COMMIT_ID} \
                           --namespace=demo ${env.NAME} ./helm/${env.NAME}"
        }
      }
    }
  }
}
