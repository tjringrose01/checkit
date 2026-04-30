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
        checkout(scm)

        script {
          def configuredBranchTag = env.BRANCH_TAG?.trim()
          def scmSelector = ''
          try {
            scmSelector = scm?.branches?.getAt(0)?.name?.trim() ?: ''
          } catch (ignored) {
            scmSelector = ''
          }

          def rawSelector = (env.TAG_NAME ?: scmSelector ?: env.BRANCH_NAME ?: configuredBranchTag ?: 'dev').trim()
          def normalizedInput = rawSelector
            .toLowerCase()
            .replaceAll("[^a-z0-9._/-]+", '-')
          def detectedReleaseTag = sh(
            script: 'git describe --tags --exact-match 2>/dev/null || true',
            returnStdout: true
          ).trim()
          def releaseTag = null

          env.RELEASE_TAG = ''
          env.RELEASE_SOURCE_BRANCH = ''
          env.SCM_BRANCH = rawSelector

          if (detectedReleaseTag ==~ /^v\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/) {
            releaseTag = detectedReleaseTag
          } else if (rawSelector.startsWith('refs/tags/')) {
            releaseTag = rawSelector.replaceFirst(/^refs\/tags\//, '')
          } else if (rawSelector ==~ /^v\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/) {
            releaseTag = rawSelector
          } else if ((env.APP_VERSION ?: '').trim() ==~ /^v\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/) {
            releaseTag = env.APP_VERSION.trim()
          }

          if (releaseTag) {
            env.BRANCH_TAG = 'prod'
            env.RELEASE_TAG = releaseTag
            env.RELEASE_SOURCE_BRANCH = 'main'
            env.APP_VERSION = (env.APP_VERSION ?: releaseTag).trim()
          } else if (
            normalizedInput == 'main' ||
            normalizedInput == '*/main' ||
            normalizedInput == 'prod'
          ) {
            env.BRANCH_TAG = 'prod'
          } else if (
            normalizedInput == 'test' ||
            normalizedInput == '*/test'
          ) {
            env.BRANCH_TAG = 'test'
          } else {
            env.BRANCH_TAG = 'dev'
          }

          echo "Build selector raw='${rawSelector}', scm='${scmSelector}', branch='${env.BRANCH_NAME ?: ''}', tag='${env.TAG_NAME ?: ''}', detected_release_tag='${detectedReleaseTag}', branch_tag='${env.BRANCH_TAG}'"
        }
      }
    }

    stage('Validate Release Tag') {
      when {
        expression { env.RELEASE_TAG?.trim() }
      }

      steps {
        sh '''
          set -eu
          git fetch --no-tags origin main
          current_tag="$(git describe --tags --exact-match 2>/dev/null || true)"

          if [ "$current_tag" != "${RELEASE_TAG}" ]; then
            echo "Checked out tag '$current_tag' does not match expected release tag '${RELEASE_TAG}'."
            exit 1
          fi

          if ! git merge-base --is-ancestor HEAD origin/main; then
            echo "Release tag '${RELEASE_TAG}' is not reachable from origin/main."
            exit 1
          fi
        '''
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
          env.RELEASE_IMAGE_TAG = (env.BRANCH_TAG == 'prod' && env.APP_VERSION?.trim()) ? "prod-${env.APP_VERSION}" : ''
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

          if [ -n "${RELEASE_IMAGE_TAG:-}" ]; then
            docker tag "${IMAGE_URI}:${GIT_SHA_SHORT:-unknown}" "${IMAGE_URI}:${RELEASE_IMAGE_TAG}"
          fi
        '''
      }
    }

    stage('SAST Scan') {
      steps {
        sh '''
          set -eu
          mkdir -p reports
          docker run --rm \
            -v "$PWD/reports:/app/reports" \
            -w /app \
            "${IMAGE_URI}:${GIT_SHA_SHORT:-unknown}" \
            bundle exec brakeman \
              --no-pager \
              --force \
              --exit-on-warn \
              --output reports/brakeman-report.json \
              --output reports/brakeman-report.txt
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
            if [ -n "${RELEASE_IMAGE_TAG:-}" ]; then
              docker push "${IMAGE_URI}:${RELEASE_IMAGE_TAG}"
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
        if [ -n "${RELEASE_IMAGE_TAG:-}" ]; then
          docker image rm "${IMAGE_URI}:${RELEASE_IMAGE_TAG}" >/dev/null 2>&1 || true
        fi
      '''
    }
    success {
      script {
        def pushedTags = ["${IMAGE_URI}:${env.GIT_SHA_SHORT}", "${IMAGE_URI}:${env.BRANCH_TAG}"]
        if (env.APP_VERSION?.trim()) {
          pushedTags << "${env.IMAGE_URI}:${env.APP_VERSION}"
        }
        if (env.RELEASE_IMAGE_TAG?.trim()) {
          pushedTags << "${env.IMAGE_URI}:${env.RELEASE_IMAGE_TAG}"
        }
        echo "Pushed ${pushedTags.join(', ')}"
      }
    }
  }
}
