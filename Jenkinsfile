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
    APP_NAME = "${env.APP_NAME ?: 'Checkit'}"
    APP_VERSION = "${env.APP_VERSION ?: ''}"
  }

  stages {
    stage('Checkout') {
      steps {
        script {
          env.BRANCH_TAG = (env.BRANCH_TAG ?: env.BRANCH_NAME ?: 'dev')
            .toLowerCase()
            .replaceAll(/[^a-z0-9._-]+/, '-')

          if (!(env.BRANCH_TAG in ['dev', 'test', 'prod'])) {
            error("BRANCH_TAG must be one of: dev, test, prod")
          }

          env.SCM_BRANCH = env.BRANCH_TAG == 'prod' ? 'main' : env.BRANCH_TAG
        }

        checkout([
          $class: 'GitSCM',
          branches: [[name: "*/${env.SCM_BRANCH}"]],
          doGenerateSubmoduleConfigurations: false,
          extensions: scm.extensions ?: [],
          submoduleCfg: [],
          userRemoteConfigs: scm.userRemoteConfigs
        ])
      }
    }

    stage('Build Image') {
      steps {
        script {
          env.GIT_SHA_SHORT = sh(
            script: 'git rev-parse --short=12 HEAD',
            returnStdout: true
          ).trim()
          env.GIT_SHA_FULL = sh(
            script: 'git rev-parse HEAD',
            returnStdout: true
          ).trim()
          env.APP_VERSION = (env.APP_VERSION ?: sh(
            script: 'git describe --tags --exact-match 2>/dev/null || true',
            returnStdout: true
          ).trim()) ?: ''
          env.APP_BUILD_TIMESTAMP = sh(
            script: 'date -u +%Y-%m-%dT%H:%M:%SZ',
            returnStdout: true
          ).trim()
          env.IMAGE_URI = "${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_REPOSITORY}"
        }

        sh '''
          set -eu
          docker build \
            --build-arg APP_NAME="${APP_NAME:-Checkit}" \
            --build-arg APP_BUILD_ENVIRONMENT="${BRANCH_TAG:-dev}" \
            --build-arg APP_BUILD_NUMBER="${BUILD_NUMBER:-local}" \
            --build-arg APP_BUILD_TIMESTAMP="${APP_BUILD_TIMESTAMP:-unknown}" \
            --build-arg APP_VERSION="${APP_VERSION:-}" \
            --build-arg APP_GIT_SHA="${GIT_SHA_FULL:-unknown}" \
            --tag "${IMAGE_URI}:${GIT_SHA_SHORT:-unknown}" \
            --tag "${IMAGE_URI}:${BRANCH_TAG:-dev}" \
            .

          if [ -n "${APP_VERSION:-}" ]; then
            docker tag "${IMAGE_URI}:${GIT_SHA_SHORT:-unknown}" "${IMAGE_URI}:${APP_VERSION}"
          fi
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
            docker push "${IMAGE_URI}:${GIT_SHA_SHORT:-unknown}"
            docker push "${IMAGE_URI}:${BRANCH_TAG:-dev}"
            if [ -n "${APP_VERSION:-}" ]; then
              docker push "${IMAGE_URI}:${APP_VERSION}"
            fi
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
        docker image rm "${IMAGE_URI}:${GIT_SHA_SHORT:-unknown}" "${IMAGE_URI}:${BRANCH_TAG:-dev}" >/dev/null 2>&1 || true
        if [ -n "${APP_VERSION:-}" ]; then
          docker image rm "${IMAGE_URI}:${APP_VERSION}" >/dev/null 2>&1 || true
        fi
      '''
    }
    success {
      script {
        def pushedTags = ["${IMAGE_URI}:${env.GIT_SHA_SHORT}", "${IMAGE_URI}:${env.BRANCH_TAG}"]
        if (env.APP_VERSION?.trim()) {
          pushedTags << "${env.IMAGE_URI}:${env.APP_VERSION}"
        }
        echo "Pushed ${pushedTags.join(', ')}"
      }
    }
  }
}
