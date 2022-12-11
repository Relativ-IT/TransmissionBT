pipeline {
  triggers {
    cron(env.BRANCH_NAME == 'main' ? '@weekly' : '')
  }

  agent {
    label 'Linux && Podman'
  }

  environment{
    REGISTRY = credentials('registry-server')
    IMAGE = "transmission4"
    TAG = "latest"
    FULLIMAGE = "${env.IMAGE}:${env.TAG}"
  }

  stages {
    stage('Initialize') {
      parallel {
        stage('Advertising start of build'){
          steps{
            slackSend color: "#4675b1", message: "${env.JOB_NAME} build #${env.BUILD_NUMBER} started :fire: (<${env.RUN_DISPLAY_URL}|Open>)"
          }
        }

        stage('Print environments variables') {
          steps {
            sh 'printenv'
          }
        }

        stage('Print Podman infos') {
          steps {
            sh '''
              podman version
              podman system info
            '''
          }
        }
      }
    }

    stage('Building image') {
      steps {
        sh 'podman build --pull -t $REGISTRY/$FULLIMAGE .'
      }
    }

    stage('Pushing image') {
      steps {
        sh 'podman push $REGISTRY/$FULLIMAGE'
      }
    }
  }

  post {
    success {
      slackSend color: "#4675b1", message: "${env.JOB_NAME} successfully built :blue_heart: !"
    }

    failure {
      slackSend color: "danger", message: "${env.JOB_NAME} build failed :poop: !"
    }
    
    cleanup {
      sh '''
        podman container prune --force
        podman image prune --force
      '''
      cleanWs()
    }
  }
}
