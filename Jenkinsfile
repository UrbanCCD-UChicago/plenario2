pipeline {
  agent any

  stages {
    stage('pre-build') {
      steps {
        step([$class, 'WsCleanup'])

        env.BUILD_VERSION = sh(script: 'date +%Y.%m.%d%H%M', returnStdout: true).trim()
        def ARTIFACT_PATH = "${env.BRANCH_NAME}/${env.BUILD_VERSION}"

        checkout scm

        sh 'mix local.hex --force'
        sh 'mix local.rebar --force'
        sh 'mix clean'
        sh 'mix deps.get'

        stash name: 'source', useDefaultExcludes: false
      }
    }

    stage('build [test]') {
      steps{
        step([$class, 'WsCleanup'])

        unstash 'source'

        withEnv(['MIX_ENV=test']) {
          sh 'mix compile'
        }

        stash 'build-test'
      }
    }

    stage('test') {
      steps {
        step([$class, 'WsCleanup'])

        unstash 'source'
        unstash 'build-test'

        withEnv(['MIX_ENV=test']) {
          sh 'mix deps.get'
        }
      }
    }
  }
}
