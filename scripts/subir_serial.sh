#!/usr/bin/env bash
# Uso (en ns1): bash subir_serial.sh <zona>    ej.: bash subir_serial.sh horizonte.internal
# Sube en 1 el serial del SOA de la zona (db.<zona>) y recarga BIND.
Z=${1:?zona}; F=/etc/bind/zonas/db.$Z
[ "$Z" = "0.44.10.in-addr.arpa" ] && F=/etc/bind/zonas/db.10.44.0
S=$(grep -oE '\( *[0-9]{10}' "$F" | grep -oE '[0-9]{10}')
sed -i "s/$S/$((S + 1))/" "$F"
rndc reload "$Z" >/dev/null && echo "$Z serial $S -> $((S + 1))"
