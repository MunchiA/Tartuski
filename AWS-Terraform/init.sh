#!/bin/bash

# Actualizar e instalar paquetes necesarios
apt update
DEBIAN_FRONTEND=noninteractive apt install -y python3-venv python3-pip pkg-config libmysqlclient-dev git

# Clonar el proyecto
cd /root
git clone https://github.com/MunchiA/TartuskiWeb.git
cd TartuskiWeb

# Crear archivo .env para la clave secreta de Flask
echo "FLASK_SECRET_KEY=tartuski321" > /root/TartuskiWeb/.env

# Crear y activar entorno virtual
python3 -m venv venv
source venv/bin/activate

# Actualizar pip e instalar Gunicorn explícitamente
pip install --upgrade pip
pip install gunicorn

# Instalar las dependencias del proyecto
pip install -r requirements.txt

# Crear servicio systemd para Gunicorn
cat <<EOF > /etc/systemd/system/tartuski.service
[Unit]
Description=Tartuski Flask Application with Gunicorn
After=network.target

[Service]
User=root
Group=root
WorkingDirectory=/root/TartuskiWeb
Environment="PATH=/root/TartuskiWeb/venv/bin"
ExecStart=/root/TartuskiWeb/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Activar y arrancar el servicio
systemctl daemon-reload
systemctl enable tartuski
systemctl start tartuski
