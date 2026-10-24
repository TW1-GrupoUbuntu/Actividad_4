#!/usr/bin/env bash
# Se ejecuta DENTRO de ns1: publica en cada zona la clave publica DKIM que genero el servidor de correo (/compartido/dkim/<dominio>.txt).
for d in horizonte familia; do
  f=/compartido/dkim/$d.internal.txt
  [ -f "$f" ] || { echo "falta $f"; continue; }
  cp "$f" /etc/bind/zonas/dkim.$d.internal.inc && chown root:bind /etc/bind/zonas/dkim.$d.internal.inc && chmod 640 /etc/bind/zonas/dkim.$d.internal.inc
  named-checkzone $d.internal /etc/bind/zonas/db.$d.internal >/dev/null && bash /lab/scripts/subir_serial.sh $d.internal
done
