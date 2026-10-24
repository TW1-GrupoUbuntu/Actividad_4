#!/usr/bin/env bash
# Se ejecuta DENTRO de un servidor de correo: cambia el selector DKIM con el que firma OpenDKIM.
# Uso: bash cambiar_selector.sh <dominio> <selector>     (si la clave del selector no existe, la genera SIN publicarla en el DNS)
D=${1:?dominio}; S=${2:?selector}; K=/etc/opendkim/keys/$D
[ -f $K/$S.private ] || opendkim-genkey -b 2048 -d $D -s $S -D $K
chown opendkim:opendkim $K/*; chmod 600 $K/*.private
echo "$S._domainkey.$D $D:$S:$K/$S.private" > /etc/opendkim/KeyTable
echo "*@$D $S._domainkey.$D" > /etc/opendkim/SigningTable
systemctl restart opendkim && echo "OpenDKIM firma ahora con el selector '$S' ($S._domainkey.$D)"
