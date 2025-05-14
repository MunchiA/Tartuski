#!/bin/bash
# Actualizar e instalar paquetes necesarios
sudo dnf update -y
sudo dnf install -y python3 python3-pip python3-devel gcc openssl-devel libffi-devel mariadb105-devel git make pkgconf zlib-devel bzip2-devel readline-devel sqlite-devel tk-devel libuuid-devel xz-devel mariadb105

# Clonar el proyecto
git clone https://github.com/MunchiA/TartuskiWeb.git
cd TartuskiWeb

# Crear y activar entorno virtual
python3 -m venv venv
source venv/bin/activate
# Instalar las dependencias del proyecto
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn
chmod +x script.sh
python3 create_tables.py

# Crear el archivo de configuración de Gunicorn
cat << 'EOF_CONF' > gunicorn.conf.py
bind = '0.0.0.0:8000'
workers = 3
timeout = 120
EOF_CONF

# Iniciar Gunicorn
gunicorn -c gunicorn.conf.py app:app &
