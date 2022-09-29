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
        stage ('Build amd64 image') {
          environment {
            NPM_TOKEN = credentials("npm-token")
          }
          steps {
            kanikoContainer(serviceAccount: 'jenkins') {
              sh "executor \
                  --context=. \
                  --destination=720913919698.dkr.ecr.us-east-1.amazonaws.com/k8s-demo-project:${env.GIT_COMMIT_ID}-amd64 \
                  --build-arg=NODE_ENV=production \
                  --build-arg=NPM_TOKEN=${env.NPM_TOKEN} \
                  --build-arg=REVISION=${env.GIT_SHA}"
            }
          }
        }
        stage ('Build arm64 image') {
          environment {
            NPM_TOKEN = credentials("npm-token")
          }
          steps {
            kanikoArm64Container(serviceAccount: 'jenkins') {
              sh "executor \
                  --context=. \
                  --destination=720913919698.dkr.ecr.us-east-1.amazonaws.com/k8s-demo-project:${env.GIT_COMMIT_ID}-arm64 \
                  --build-arg=NODE_ENV=production \
                  --build-arg=NPM_TOKEN=${env.NPM_TOKEN} \
                  --build-arg=REVISION=${env.GIT_SHA}"
            }
          }
        }
      }
    }
    stage ('Push multi-arch image') {
      steps {
        manifestContainer() {
                  sh "sleep 300"
                  sh "manifest-tool inspect 720913919698.dkr.ecr.us-east-1.amazonaws.com/k8s-demo-project:c9f2afbf4d72154cfa5979db6272e76c5cfe4ac1"
                  sh """
                      manifest-tool push from-args \
                        --platforms linux/amd64,linux/arm64 \
                        --template ${env.ECR}/${env.NAME}:${env.GIT_COMMIT_ID}-ARCH \
                        --target ${env.ECR}/${env.NAME}:${env.GIT_COMMIT_ID}
                      """
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
