pipeline {
  agent any

  options {
    disableConcurrentBuilds()
    timestamps()
  }

  environment {
    DOCKER_REGISTRY = "${env.DOCKER_REGISTRY ?: 'docker.io'}"
    DOCKER_IMAGE_REPOSITORY = "${env.DOCKER_IMAGE_REPOSITORY ?: 'tjringrose01/checkit'}"
    DOCKER_CREDENTIALS_ID = "${env.DOCKER_CREDENTIALS_ID ?: 'dockerhub_id'}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Image') {
      steps {
        script {
          env.GIT_SHA_SHORT = sh(
            script: 'git rev-parse --short=12 HEAD',
            returnStdout: true
          ).trim()
          env.BRANCH_TAG = (env.BRANCH_NAME ?: 'manual')
            .toLowerCase()
            .replaceAll(/[^a-z0-9._-]+/, '-')
          env.IMAGE_URI = "${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_REPOSITORY}"
        }

        sh '''
          set -eu
          docker build \
            --tag "${IMAGE_URI}:${GIT_SHA_SHORT}" \
            --tag "${IMAGE_URI}:${BRANCH_TAG}" \
            .
        '''
      }
    }

    stage('Push Image') {
      steps {
        withCredentials([
          usernamePassword(
            credentialsId: env.DOCKER_CREDENTIALS_ID,
            usernameVariable: 'DOCKER_USERNAME',
            passwordVariable: 'DOCKER_PASSWORD'
          )
        ]) {
          sh '''
            set -eu
            echo "${DOCKER_PASSWORD}" | docker login "${DOCKER_REGISTRY}" --username "${DOCKER_USERNAME}" --password-stdin
            docker push "${IMAGE_URI}:${GIT_SHA_SHORT}"
            docker push "${IMAGE_URI}:${BRANCH_TAG}"
            docker logout "${DOCKER_REGISTRY}"
          '''
        }
      }
    }
  }

  post {
    always {
      sh '''
        set +e
        docker image rm "${IMAGE_URI}:${GIT_SHA_SHORT}" "${IMAGE_URI}:${BRANCH_TAG}" >/dev/null 2>&1 || true
      '''
    }
    success {
      echo "Pushed ${IMAGE_URI}:${GIT_SHA_SHORT} and ${IMAGE_URI}:${BRANCH_TAG}"
    }
  }
}
