pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "ikramegouaiche212003/student-web-app"
        DOCKER_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Récupération du code source...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Construction de l\'image Docker...'
                bat '''
                docker build -t %DOCKER_IMAGE%:%DOCKER_TAG% .
                docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_IMAGE%:latest
                '''
            }
        }

        stage('Test') {
            steps {
                echo 'Tests de l\'application...'
                bat '''
                docker run -d --name test-container -p 8080:80 %DOCKER_IMAGE%:latest
                timeout /t 10
                curl -f http://localhost:8080 || exit 1
                docker stop test-container
                docker rm test-container
                '''
            }
        }

        stage('Release') {
            steps {
                echo 'Publication sur Docker Hub...'
                withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    bat '''
                    echo %PASSWORD% | docker login -u %USERNAME% --password-stdin
                    docker push %DOCKER_IMAGE%:%DOCKER_TAG%
                    docker push %DOCKER_IMAGE%:latest
                    '''
                }
            }
        }

        stage('Deploy to Review') {
            steps {
                echo 'Déploiement en environnement de review...'
                bat '''
                docker run -d --name review-app -p 9001:80 %DOCKER_IMAGE%:latest
                echo "Application déployée sur http://localhost:9001"
                '''
            }
        }

        stage('Deploy to Staging') {
            steps {
                echo 'Déploiement en environnement de staging...'
                bat '''
                docker run -d --name staging-app -p 9002:80 %DOCKER_IMAGE%:latest
                echo "Application déployée sur http://localhost:9002"
                '''
            }
        }        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                echo 'Déploiement en production...'
                input message: 'Déployer en production?', ok: 'Déployer'
                bat '''
                docker run -d --name prod-app -p 9003:80 %DOCKER_IMAGE%:latest
                echo "Application déployée en production sur http://localhost:9003"
                '''
            }
        }
    }
