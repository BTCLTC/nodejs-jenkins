pipeline {
  agent {
    kubernetes {
      inheritFrom 'nodejs base'
    }

  }
  environment {
    REGISTRY = 'harbor.xxxxxx.com'
    DOCKERHUB_NAMESPACE = 'harbor_namespace'
    APP_NAME = 'nodejs-jenkins'
  }
  stages {
    stage('clone code') {
      agent none
      steps {
        container('base') {
          git(url: 'https://github.com/xxxxx/xxxxxx', credentialsId: 'github', branch: 'main', changelog: true, poll: false)

          script {
            def PACKAGE_VERSION = sh(script: '''grep version package.json | cut -d '"' -f4''', returnStdout: true).trim()
            def NEW_VERSION = "v${PACKAGE_VERSION}-$BUILD_NUMBER"
            env.VERSION = NEW_VERSION
          }
        }

      }
    }

    stage('code analysis') {
      agent none
      steps {
        container('nodejs') {
          withCredentials([string(credentialsId: 'sonar', variable: 'SONAR_TOKEN')]) {
            withSonarQubeEnv('sonar') {
              sh 'sonar-scanner -Dsonar.projectKey=node -Dsonar.host.url=https://sonar.xxxxx.com -Dsonar.login=$SONAR_TOKEN'
            }

          }

          timeout(unit: 'HOURS', activity: false, time: 1) {
            waitForQualityGate 'true'
          }

        }

      }
    }

    stage('build & push') {
      agent none
      steps {
        container('base') {
          echo "Build version: $VERSION"
          sh 'docker build -f Dockerfile -t $REGISTRY/$DOCKERHUB_NAMESPACE/$APP_NAME:$VERSION .'
          withCredentials([usernamePassword(credentialsId: 'harbor', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
            sh 'echo "$PASSWORD" | docker login $REGISTRY -u "$USERNAME" --password-stdin'
            sh 'docker push $REGISTRY/$DOCKERHUB_NAMESPACE/$APP_NAME:$VERSION'
          }

        }

      }
    }

    stage('push latest') {
      agent none
      steps {
        container('base') {
          sh 'docker tag $REGISTRY/$DOCKERHUB_NAMESPACE/$APP_NAME:$VERSION $REGISTRY/$DOCKERHUB_NAMESPACE/$APP_NAME:latest '
          sh 'docker push $REGISTRY/$DOCKERHUB_NAMESPACE/$APP_NAME:latest '
        }

      }
    }

    stage('deploy to production') {
      agent none
      steps {
        container('base') {
          withCredentials([kubeconfigFile(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
            sh 'kubectl kustomize deploy/prod | envsubst | kubectl apply -f -'
          }

        }

      }
    }

  }
}
