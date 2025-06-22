# Script AWS EC2 - Déploiement automatisé
#!/bin/bash

echo "========================================="
echo "    DÉPLOIEMENT SUR AWS EC2"
echo "========================================="

echo "[1/4] Mise à jour du système..."
sudo apt update -y

echo "[2/4] Installation de Docker et Docker Compose (si nécessaire)..."
if ! command -v docker &> /dev/null; then
    sudo apt install docker.io -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
fi

if ! command -v docker-compose &> /dev/null; then
    sudo apt install docker-compose -y
fi

echo "[3/4] Déploiement de l'application avec Docker Compose..."
sudo docker-compose down || true
sudo docker-compose pull
sudo docker-compose up --build docker-compose-dev.yml -d --remove-orphans

echo "========================================="
echo "✅ Déploiement terminé avec succès!"
echo "📊 Statut des conteneurs:"
sudo docker ps
echo "========================================="
