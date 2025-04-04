pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "ikramegouaiche212003/devops-mini-projet" 
    }

    stages {
        stage('Build') {
            steps {
                bat '''
                docker-compose up --build -d
                '''
            }
        }
        stage('Test') {
            steps {
                bat '''
                timeout /t 20
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
        stage ('DeployReview') {
            steps {
                bat '''
                    ssh -o StrictHostKeyChecking=no ec2-user@13.60.22.150 whoami
                '''
            }
        }

    }
}
