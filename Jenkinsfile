pipeline {
  agent any

  stages {
    stage('pre build') {
      steps {
        checkout scm

        sh 'sudo add-apt-repository ppa:ubuntugis/ppa'
        sh 'sudo apt-get update'
        sh 'sudo apt-get install gdal-bin'

        sh 'mix local.hex --force'
        sh 'mix local.rebar --force'
        sh 'mix clean'
        sh 'mix deps.get'

        stash name: 'source'
      }
    }

    stage('build [test]') {
      steps{
        unstash 'source'

        withEnv(['MIX_ENV=test']) {
          sh 'mix compile'
        }

        stash 'build-test'
      }
    }

    stage('test') {
      steps {
        unstash 'source'
        unstash 'build-test'

        withEnv(['MIX_ENV=test']) {
          sh 'mix deps.get'
          sh 'mix ecto.drop'
          sh 'mix ecto.create'
          sh 'mix ecto.migrate'
          sh 'mix coveralls'
        }
      }
    }
  }
}
