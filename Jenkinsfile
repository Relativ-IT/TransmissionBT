pipeline {
  triggers {
    cron(env.BRANCH_NAME == 'Release' ? '@weekly' : '')
  }

  agent {
    label 'Linux && Podman'
  }

  environment {
    IMAGE = "transmission"
    TRANSMISSION_LATEST_TAG = "4.0.5"
    TRANSMISSION_MAIN_TAG = "main"

    IMAGE_LATEST_IMAGE_NAME = "${env.IMAGE}:latest"
    IMAGE_MAIN_IMAGE_NAME = "${env.IMAGE}:${env.TRANSMISSION_MAIN_TAG}"
    IMAGE_LATEST_TAG_NAME = "${env.IMAGE}:${env.TRANSMISSION_LATEST_TAG}"

    LOCAL_REGISTRY_IMAGE_TAG_NAME = "${env.REGISTRY_LOCAL}/${env.IMAGE_LATEST_TAG_NAME}"
    LOCAL_REGISTRY_IMAGE_LATEST_NAME = "${env.REGISTRY_LOCAL}/${env.IMAGE_LATEST_IMAGE_NAME}"
    LOCAL_REGISTRY_IMAGE_MAIN_NAME = "${env.REGISTRY_LOCAL}/${env.IMAGE_MAIN_IMAGE_NAME}"
    DOCKERHUB_REGISTRY_IMAGE_TAG_NAME = "${env.REGISTRY_DOCKERHUB}/${env.IMAGE_LATEST_TAG_NAME}"
    DOCKERHUB_REGISTRY_IMAGE_LATEST_NAME = "${env.REGISTRY_DOCKERHUB}/${env.IMAGE_LATEST_IMAGE_NAME}"
    DOCKERHUB_REGISTRY_IMAGE_MAIN_NAME = "${env.REGISTRY_DOCKERHUB}/${env.IMAGE_MAIN_IMAGE_NAME}"
  }

  stages {
    stage('Initialize') {
      parallel {
        stage('Advertising start of build') {
          steps{
            slackSend color: "#4675b1", message: "${env.JOB_NAME} build #${env.BUILD_NUMBER} started :fire: (<${env.RUN_DISPLAY_URL}|Open>)"
          }
        }

        stage('Print environments variables') {
          steps {
            sh 'printenv | sort'
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
          podman build --pull --cache-ttl=1h --build-arg BRANCH=$TRANSMISSION_LATEST_TAG -t $LOCAL_REGISTRY_IMAGE_TAG_NAME .

          podman tag $LOCAL_REGISTRY_IMAGE_TAG_NAME $LOCAL_REGISTRY_IMAGE_LATEST_NAME
          podman tag $LOCAL_REGISTRY_IMAGE_TAG_NAME $DOCKERHUB_REGISTRY_IMAGE_LATEST_NAME
          podman tag $LOCAL_REGISTRY_IMAGE_TAG_NAME $DOCKERHUB_REGISTRY_IMAGE_TAG_NAME

          podman build --pull --cache-ttl=1h --build-arg BRANCH=$TRANSMISSION_MAIN_TAG -t $LOCAL_REGISTRY_IMAGE_MAIN_NAME .
          podman tag $LOCAL_REGISTRY_IMAGE_MAIN_NAME $DOCKERHUB_REGISTRY_IMAGE_MAIN_NAME
        '''
      }
    }

    stage("Login to Docker hub") {
      when {branch 'Release'}
      steps {
        withCredentials([usernamePassword(credentialsId: 'DockerHub_credentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
          sh 'podman login -u $USERNAME -p $PASSWORD docker.io'
        }
      }
    }

    stage('Pushing images') {
      when {branch 'Release'}
      parallel{
        stage("Push latest image to local registry") {
          steps {
            sh 'podman push $LOCAL_REGISTRY_IMAGE_LATEST_NAME'
          }
        }

        stage("Push tagged image to local registry") {
          steps {
            sh 'podman push $LOCAL_REGISTRY_IMAGE_TAG_NAME'
          }
        }

        stage("Push main image to local registry") {
          steps {
            sh 'podman push $LOCAL_REGISTRY_IMAGE_MAIN_NAME'
          }
        }

        stage("Push latest image to Docker hub") {
          steps {
            sh 'podman push $DOCKERHUB_REGISTRY_IMAGE_LATEST_NAME'
          }
        }

        stage("Push tagged image to Docker hub") {
          steps {
            sh 'podman push $DOCKERHUB_REGISTRY_IMAGE_TAG_NAME'
          }
        }

        stage("Push main image to Docker hub") {
          steps {
            sh 'podman push $DOCKERHUB_REGISTRY_IMAGE_MAIN_NAME'
          }
        }
      }
    }

    stage("Logout from Docker hub") {
      when {branch 'Release'}
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
      cleanWs()
    }
  }
}
