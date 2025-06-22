# Script AWS EC2 - Déploiement automatisé
#!/bin/bash

echo "========================================="
echo "    DÉPLOIEMENT SUR AWS EC2"
echo "========================================="

# Variables
IMAGE_NAME="ikramegouaiche212003/student-web-app:latest"
CONTAINER_NAME="student-app-prod"
PORT="80"

echo "[1/4] Mise à jour du système..."
sudo apt update -y

echo "[2/4] Installation de Docker (si nécessaire)..."
if ! command -v docker &> /dev/null; then
    sudo apt install docker.io -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
fi

echo "[3/4] Téléchargement de l'image depuis Docker Hub..."
sudo docker pull $IMAGE_NAME

echo "[4/4] Déploiement de l'application..."
# Arrêt du conteneur existant s'il existe
sudo docker stop $CONTAINER_NAME 2>/dev/null || true
sudo docker rm $CONTAINER_NAME 2>/dev/null || true

# Démarrage du nouveau conteneur
sudo docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p $PORT:80 \
    $IMAGE_NAME

echo "========================================="
echo "✅ Déploiement terminé avec succès!"
echo "🌐 Application accessible sur: http://13.220.160.176$(curl -s http://13.220.160.176)"
echo "📊 Statut du conteneur:"
sudo docker ps | grep $CONTAINER_NAME
echo "========================================="
