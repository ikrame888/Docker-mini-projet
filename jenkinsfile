pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "ikramegouaiche212003/devops-mini-projet"  // Your Docker Hub repo
    }

    stages {
        stage('Clone Repository') {
            steps {
                sh '''
                git clone https://github.com/ikrame888/Docker-mini-projet.git
                cd Docker-mini-projet
                '''
            }
        }

        stage('Build & Run Containers') {
            steps {
                sh '''
                cd Docker-mini-projet
                docker-compose up --build -d
                '''
            }
        }

        stage('Test API') {
            steps {
                sh '''
                sleep 10  # Wait for the service to start
                curl -u root:root -X GET http://localhost:5000/supmit/api/v1.0/get_student_ages
                '''
            }
        }

        stage('Release & Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                    sh '''
                    echo "$TOKEN" | docker login -u "$USERNAME" --password-stdin
                    docker tag docker-mini-projet-supmit_api $DOCKER_IMAGE
                    docker push $DOCKER_IMAGE
                    '''
                }
            }
        }
    }
}
