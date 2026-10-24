#!/usr/bin/env bash
# Levanta todo el entorno de la Actividad 4 desde cero (desde WSL, en la carpeta del repositorio):
#   bash scripts/levantar.sh
set -e
cd "$(dirname "$0")/.."
mkdir -p compartido
[ -f compartido/clave_buzones ] || { openssl rand -base64 18 | tr -d '/+=' | cut -c1-20 > compartido/clave_buzones; chmod 600 compartido/clave_buzones; }
docker compose -p act4 up -d --build
echo "esperando a systemd..."; sleep 12
x() { docker exec -w /lab "act4-$1" bash "${@:2}"; }
x ns1 scripts/instalar_dns.sh
x cliente scripts/crear_ca.sh
x mail2 scripts/instalar_correo.sh familia.internal "rosa pedro" no
x mail  scripts/instalar_correo.sh horizonte.internal "ana luis marta" si
x ns1 scripts/publicar_dkim.sh
x cliente scripts/preparar_cliente.sh
x externo scripts/preparar_cliente.sh
echo "Entorno listo. Verificacion:  docker exec -w /lab act4-cliente bash scripts/verificar.sh"
