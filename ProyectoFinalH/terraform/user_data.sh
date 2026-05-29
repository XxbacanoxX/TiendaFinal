!/bin/bash
set -e

exec > /var/log/user-data.log 2>&1
echo "=== Inicio user_data $(date) ==="

dnf update -y
dnf install -y docker git
systemctl enable docker
systemctl start docker

mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/download/v2.27.1/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
usermod -aG docker ec2-user

cd /home/ec2-user

git clone https://github.com/XxbacanoxX/TiendaFinal.git proyecto-tienda

cd proyecto-tienda
docker compose up --build -d

echo "=== Despliegue de la tienda completado $(date) ==="