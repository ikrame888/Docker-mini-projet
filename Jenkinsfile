pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "ikramegouaiche212003/devops-mini-projet"  // Your Docker Hub repo
    }

    stages {
        stage('Build') {
            steps {
                // Use cmd to clone the repository and run docker-compose
                bat '''
                git clone https://github.com/ikrame888/Docker-mini-projet.git
                cd Docker-mini-projet
                docker-compose up --build -d
                '''
            }
        }
        stage('Test') {
            steps {
                // Use cmd to pause for 10 seconds and then perform the curl request
                bat '''
                timeout /t 10
                curl -u root:root -X GET http://localhost:5000/supmit/api/v1.0/get_student_ages
                '''
            }
        }
        
        stage ('Release') {
    steps {
        withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
            bat '''
            echo %TOKEN% | docker login -u %USERNAME% --password-stdin
            docker tag docker-mini-projet-supmit_api %DOCKER_IMAGE%
            docker push %DOCKER_IMAGE%
            '''
        }
    }
}

    }
}
