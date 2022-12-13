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
    DOCKER_IMAGE = "docker.io/nemric/tansmission:beta2"
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

    stage('Pushing images') {
      parallel{
        stage("push to local registry"){
          steps {
            sh 'podman push $REGISTRY/$FULLIMAGE'
          }
        }

        stage("push to Docker hub"){
          steps {
            withCredentials([usernamePassword(credentialsId: 'DockerHub_credentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]){
              sh '''
                podman tag $REGISTRY/$FULLIMAGE $DOCKER_IMAGE
                podman login -u $USERNAME -p $PASSWORD docker.io
                podman push $DOCKER_IMAGE
              '''
            }
          }
        }
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
