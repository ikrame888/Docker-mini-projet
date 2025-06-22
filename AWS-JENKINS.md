# Configuration Jenkins avec AWS - Guide Complet

## Prérequis AWS

### 1. Créer un compte AWS
- Connectez-vous à [AWS Console](https://aws.amazon.com)
- Créez un compte si vous n'en avez pas

### 2. Configuration IAM (Identity and Access Management)

#### Créer un utilisateur IAM pour Jenkins
1. **Accédez au service IAM**
2. **Créez un nouvel utilisateur :**
   ```
   Nom d'utilisateur : jenkins-ci-user
   Type d'accès : Accès programmatique
   ```

3. **Attachez les politiques nécessaires :**
   - `AmazonEC2FullAccess`
   - `AmazonECS_FullAccess` 
   - `AmazonS3FullAccess`
   - Ou créez une politique personnalisée :

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "ecs:*",
                "s3:*",
                "logs:*",
                "iam:PassRole"
            ],
            "Resource": "*"
        }
    ]
}
```

4. **Sauvegardez les clés :**
   - Access Key ID
   - Secret Access Key

## Configuration EC2 pour le déploiement

### 1. Lancer une instance EC2

#### Via AWS Console :
1. **Accédez à EC2 Dashboard**
2. **Lancez une nouvelle instance :**
   ```
   AMI : Ubuntu Server 22.04 LTS
   Type d'instance : t2.micro (éligible au niveau gratuit)
   Groupe de sécurité : Ouvrir les ports 22, 80, 443
   ```

3. **Téléchargez la paire de clés PEM**

#### Via AWS CLI :
```bash
# Créer une paire de clés
aws ec2 create-key-pair --key-name jenkins-key --query 'KeyMaterial' --output text > jenkins-key.pem

# Lancer l'instance
aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --count 1 \
    --instance-type t2.micro \
    --key-name jenkins-key \
    --security-groups jenkins-sg
```

### 2. Configuration de l'instance EC2

```bash
# Connexion SSH
ssh -i jenkins-key.pem ubuntu@<IP-PUBLIQUE>

# Installation Docker
sudo apt update
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

# Installation AWS CLI
sudo apt install awscli -y
```

## Configuration Jenkins

### 1. Installation des plugins Jenkins

Dans Jenkins Dashboard → Manage Jenkins → Manage Plugins :

**Plugins requis :**
- AWS Steps Plugin
- Amazon EC2 Plugin
- Docker Pipeline Plugin
- SSH Agent Plugin
- Publish Over SSH Plugin

### 2. Configuration des Credentials

#### Credentials AWS (Access Keys)
```
Kind: Secret text
Scope: Global
Secret: <YOUR-ACCESS-KEY-ID>
ID: aws-access-key-id
```

```
Kind: Secret text  
Scope: Global
Secret: <YOUR-SECRET-ACCESS-KEY>
ID: aws-secret-access-key
```

#### Credentials SSH pour EC2
```
Kind: SSH Username with private key
Scope: Global
Username: ubuntu
Private Key: <CONTENU-DU-FICHIER-PEM>
ID: ec2-ssh-key
```

#### Credentials Docker Hub
```
Kind: Username with password
Scope: Global
Username: <VOTRE-USERNAME-DOCKERHUB>
Password: <VOTRE-TOKEN-DOCKERHUB>
ID: docker-hub
```

### 3. Configuration du Cloud EC2

1. **Manage Jenkins → Manage Nodes and Clouds → Configure Clouds**
2. **Add a new cloud → Amazon EC2**
3. **Configuration :**
   ```
   Cloud Name: aws-cloud
   Amazon EC2 Credentials: aws-access-key-id, aws-secret-access-key
   Region: us-east-1 (ou votre région)
   EC2 Key Pair's Private Key: ec2-ssh-key
   ```

## Jenkinsfile avec déploiement AWS

Voici un Jenkinsfile modifié pour AWS :

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "ikramegouaiche212003/student-web-app"
        DOCKER_TAG = "${BUILD_NUMBER}"
        AWS_REGION = "us-east-1"
        EC2_HOST = "ec2-user@<VOTRE-IP-EC2>"
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
                script {
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                    docker.build("${DOCKER_IMAGE}:latest")
                }
            }
        }
        
        stage('Test') {
            steps {
                echo 'Tests de l\'application...'
                script {
                    def testContainer = docker.run("-d -p 8080:80", "${DOCKER_IMAGE}:latest")
                    sleep 10
                    sh 'curl -f http://localhost:8080 || exit 1'
                    testContainer.stop()
                }
            }
        }
        
        stage('Release') {
            steps {
                echo 'Publication sur Docker Hub...'
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub') {
                        def image = docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}")
                        image.push()
                        image.push("latest")
                    }
                }
            }
        }
        
        stage('Deploy to AWS EC2') {
            steps {
                echo 'Déploiement sur AWS EC2...'
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${EC2_HOST} "
                            # Arrêter l'ancien conteneur
                            docker stop student-app || true
                            docker rm student-app || true
                            
                            # Télécharger la nouvelle image
                            docker pull ${DOCKER_IMAGE}:${DOCKER_TAG}
                            
                            # Démarrer le nouveau conteneur
                            docker run -d \\
                                --name student-app \\
                                --restart unless-stopped \\
                                -p 80:80 \\
                                ${DOCKER_IMAGE}:${DOCKER_TAG}
                        "
                    '''
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Déploiement réussi sur AWS!'
        }
        failure {
            echo 'Échec du déploiement'
        }
    }
}
```

## Script de déploiement automatisé AWS

Créez ce script sur votre instance EC2 :

```bash
#!/bin/bash
# deploy-to-ec2.sh

APP_NAME="student-web-app"
IMAGE_NAME="ikramegouaiche212003/student-web-app"
CONTAINER_NAME="student-app"

echo "Déploiement de $APP_NAME sur AWS EC2"

# Arrêter l'ancien conteneur
echo "Arrêt de l'ancien conteneur..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# Télécharger la dernière image
echo "Téléchargement de l'image $IMAGE_NAME..."
docker pull $IMAGE_NAME:latest

# Démarrer le nouveau conteneur
echo "Démarrage du nouveau conteneur..."
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p 80:80 \
    $IMAGE_NAME:latest

# Vérifier le statut
echo "Vérification du déploiement..."
sleep 5
if docker ps | grep -q $CONTAINER_NAME; then
    echo "Déploiement réussi!"
else
    echo "Échec du déploiement"
    exit 1
fi
```

## Monitoring et Logs

### CloudWatch Logs (Optionnel)
```bash
# Installation de l'agent CloudWatch
sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Configuration pour Docker logs
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```

### Vérification des logs Docker
```bash
# Logs du conteneur
docker logs student-app

# Logs en temps réel
docker logs -f student-app
```

## Résumé des étapes

1. ✅ Créer un compte AWS et configurer IAM
2. ✅ Lancer une instance EC2 Ubuntu
3. ✅ Installer Docker sur EC2
4. ✅ Configurer Jenkins avec les plugins AWS
5. ✅ Ajouter les credentials AWS et SSH
6. ✅ Modifier le Jenkinsfile pour AWS
7. ✅ Tester le pipeline complet

Votre application sera accessible via l'IP publique de votre instance EC2 !
