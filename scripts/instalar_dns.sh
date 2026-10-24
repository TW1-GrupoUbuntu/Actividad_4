#!/usr/bin/env bash
# Se ejecuta DENTRO de ns1: instala las zonas del laboratorio y arranca BIND.
set -e
install -d -o root -g bind -m 755 /etc/bind/zonas
cp /lab/dns/named.conf.options /lab/dns/named.conf.local /etc/bind/
for z in db.horizonte.internal db.familia.internal db.10.44.0; do cp /lab/dns/$z /etc/bind/zonas/; done
for d in horizonte familia; do [ -f /etc/bind/zonas/dkim.$d.internal.inc ] || echo "; clave DKIM de $d.internal (la publica scripts/publicar_dkim.sh)" > /etc/bind/zonas/dkim.$d.internal.inc; done
chown -R root:bind /etc/bind/zonas; chmod 640 /etc/bind/zonas/*
named-checkconf
named-checkzone horizonte.internal /etc/bind/zonas/db.horizonte.internal >/dev/null
named-checkzone familia.internal /etc/bind/zonas/db.familia.internal >/dev/null
named-checkzone 0.44.10.in-addr.arpa /etc/bind/zonas/db.10.44.0 >/dev/null
systemctl enable named >/dev/null 2>&1; systemctl restart named
sleep 2; systemctl is-active named
