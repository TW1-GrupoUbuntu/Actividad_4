#!/usr/bin/env bash
# Se ejecuta DENTRO de "cliente": instala Thunderbird (binario oficial de Mozilla), una pantalla virtual y utilidades de captura.
# En Ubuntu 24.04 el paquete "thunderbird" es un snap, que no funciona dentro de un contenedor.
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends xvfb xdotool imagemagick x11-utils bzip2 xz-utils \
  libgtk-3-0t64 libdbus-glib-1-2 libasound2t64 libx11-xcb1 libxt6t64 libxtst6 fonts-dejavu-core fonts-noto-color-emoji dbus-x11 >/dev/null
cd /opt
if [ ! -x /opt/thunderbird/thunderbird ]; then
  curl -fsSL -o tb.tar.xz "https://download.mozilla.org/?product=thunderbird-latest&os=linux64&lang=es-ES" 2>/dev/null \
   || curl -fsSL -o tb.tar.xz "https://download.mozilla.org/?product=thunderbird-latest&os=linux64&lang=en-US"
  tar -xf tb.tar.xz && rm tb.tar.xz
fi
ln -sf /opt/thunderbird/thunderbird /usr/local/bin/thunderbird
/opt/thunderbird/thunderbird --version
