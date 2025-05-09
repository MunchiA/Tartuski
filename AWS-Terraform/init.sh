#!/bin/bash
# Actualizar e instalar paquetes necesarios
sudo dnf update -y
sudo dnf install -y python3 python3-pip pkgconf git dbus-devel glib2-devel cairo-devel python3-devel gobject-introspection-devel libicu-devel dbus-daemon cairo-gobject-devel gcc-c++

# Clonar el proyecto
git clone https://github.com/MunchiA/TartuskiWeb.git
cd TartuskiWeb

# Crear archivo .env para la clave secreta de Flask
echo "FLASK_SECRET_KEY=tartuski321" > .env

# Crear y activar entorno virtual
python3 -m venv venv
source venv/bin/activate

# Instalar las dependencias del proyecto
pip install --upgrade pip

# Ajustes en requirements.txt
sed -i 's/^cryptography==.*$/cryptography==41.0.3/' requirements.txt
sed -i '/^ufw==/d' requirements.txt
sed -i '/^ubuntu-pro-client==/d' requirements.txt
sed -i '/^command-not-found==/d' requirements.txt
sed -i 's/^distro-info==1.7+build1$/distro-info==1.0/' requirements.txt
sed -i '/^python-apt==2.7.7+ubuntu4/d' requirements.txt

pip install -r requirements.txt
pip install gunicorn

# Crear el archivo de configuración de Gunicorn
cat << 'EOF_CONF' > gunicorn.conf.py
bind = '0.0.0.0:8000'
workers = 3
timeout = 120
EOF_CONF

# Iniciar Gunicorn
gunicorn -c gunicorn.conf.py app:app &
