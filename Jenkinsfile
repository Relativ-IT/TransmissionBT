pipeline {
  triggers {
    cron(env.BRANCH_NAME == 'main' ? '@weekly' : '')
  }

  agent {
    label 'Linux && Podman'
  }

  environment{
    LOCAL_REGISTRY = credentials('registry-server')
    IMAGE = "transmission4"
    TRANSMISSION_LATEST_TAG = "4.0.2"
    DOCKERHUB_IMAGE_PATH = "docker.io/nemric/transmission"
    IMAGE_LATEST_IMAGE_NAME = "${env.IMAGE}:latest"
    IMAGE_LATEST_TAG_NAME = "${env.IMAGE}:${env.TRANSMISSION_LATEST_TAG}"

    LOCAL_REGISTRY_IMAGE_TAG_NAME = "${env.LOCAL_REGISTRY}/${env.IMAGE_LATEST_TAG_NAME}"
    LOCAL_REGISTRY_IMAGE_LATEST_NAME = "${env.LOCAL_REGISTRY}/${env.IMAGE_LATEST_IMAGE_NAME}"
    DOCKERHUB_REGISTRY_IMAGE_TAG_NAME = "${env.DOCKERHUB_IMAGE_PATH}/${env.IMAGE_LATEST_TAG_NAME}"
    DOCKERHUB_REGISTRY_IMAGE_LATEST_NAME = "${env.DOCKERHUB_IMAGE_PATH}/${env.IMAGE_LATEST_IMAGE_NAME}"
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

    stage('Build & tag images') {
      steps {
        sh '''
          podman build --pull --build-arg LatestTag=$TRANSMISSION_LATEST_TAG -t $LOCAL_REGISTRY_IMAGE_TAG_NAME .
          podman tag $LOCAL_REGISTRY_IMAGE_TAG_NAME $LOCAL_REGISTRY_IMAGE_LATEST_NAME
          podman tag $LOCAL_REGISTRY_IMAGE_TAG_NAME $DOCKERHUB_REGISTRY_IMAGE_LATEST_NAME
          podman tag $LOCAL_REGISTRY_IMAGE_TAG_NAME $DOCKERHUB_REGISTRY_IMAGE_TAG_NAME
        '''
      }
    }

    stage("Login to Docker hub"){
      steps {
        withCredentials([usernamePassword(credentialsId: 'DockerHub_credentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]){
          sh 'podman login -u $USERNAME -p $PASSWORD docker.io'
        }
      }
    }

    stage('Pushing images') {
      parallel{
        stage("Push latest image to local registry"){
          steps {
            sh 'podman push $LOCAL_REGISTRY_IMAGE_LATEST_NAME'
          }
        }

        stage("Push tagged image to local registry"){
          steps {
            sh 'podman push $LOCAL_REGISTRY_IMAGE_TAG_NAME'
          }
        }

        stage("Push latest image to Docker hub"){
          steps {
            withCredentials([usernamePassword(credentialsId: 'DockerHub_credentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]){
              sh 'podman push $DOCKERHUB_REGISTRY_IMAGE_LATEST_NAME'
            }
          }
        }

        stage("Push tagged image to Docker hub"){
          steps {
            sh 'podman push $DOCKERHUB_REGISTRY_IMAGE_TAG_NAME'
          }
        }
      }
    }

    stage("Logout from Docker hub"){
      steps {
        sh 'podman logout docker.io'
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
