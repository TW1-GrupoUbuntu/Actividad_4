#!/usr/bin/env bash
# Crea la CA del laboratorio y un certificado por servidor de correo en /compartido (las claves privadas no se suben al repositorio).
set -e
C=/compartido/ca; mkdir -p $C /compartido/certs; cd $C
[ -f ca.key ] || openssl req -x509 -newkey rsa:3072 -nodes -keyout ca.key -out ca.crt -days 825 -subj "/C=BO/O=U.E. Horizonte/CN=CA del laboratorio de correo" 2>/dev/null
emitir() { # emitir <host> <san...>
  h=$1; shift; san=$(printf 'DNS:%s,' "$@"); san=${san%,}
  [ -f /compartido/certs/$h.crt ] && return
  openssl req -newkey rsa:2048 -nodes -keyout /compartido/certs/$h.key -out /tmp/$h.csr -subj "/C=BO/O=U.E. Horizonte/CN=$h" 2>/dev/null
  printf 'subjectAltName=%s\nextendedKeyUsage=serverAuth\nbasicConstraints=CA:FALSE\n' "$san" > /tmp/$h.ext
  openssl x509 -req -in /tmp/$h.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out /compartido/certs/$h.crt -days 397 -sha256 -extfile /tmp/$h.ext 2>/dev/null
}
emitir mail.horizonte.internal mail.horizonte.internal imap.horizonte.internal smtp.horizonte.internal
emitir mail.familia.internal mail.familia.internal
chmod 600 /compartido/certs/*.key ca.key
echo "CA y certificados listos:"; ls /compartido/certs | tr '\n' ' '; echo
