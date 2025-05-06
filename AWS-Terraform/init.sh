#!/bin/bash

# Actualizar e instalar paquetes
apt update
apt install -y python3-venv python3-pip nginx python3-certbot-nginx pkg-config libmysqlclient-dev git

# Clonar el proyecto
cd /root
git clone https://github.com/MunchiA/TartuskiWeb.git
cd TartuskiWeb

# Crear entorno virtual e instalar dependencias
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
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
ExecStart=/root/TartuskiWeb/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Activar servicio
systemctl daemon-reload
systemctl enable tartuski
systemctl start tartuski

# Configurar Nginx como proxy inverso
cat <<EOF > /etc/nginx/sites-available/tartuski
server {
    listen 80;
    server_name tartuski.cat www.tartuski.cat;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -s /etc/nginx/sites-available/tartuski /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Instalar certificado SSL con Certbot
certbot --nginx --non-interactive --agree-tos -m tartuski.corp@gmail.com -d tartuski.cat -d www.tartuski.cat
