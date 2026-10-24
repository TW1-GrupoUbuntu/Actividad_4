# Ubuntu 24.04 con systemd y todo el software de correo de la Actividad 4:
# Postfix, Dovecot (IMAP/LMTP/Sieve), OpenDKIM, OpenDMARC, SPF (policyd-spf), Rspamd, ClamAV, BIND9 y herramientas de prueba.
# Cada contenedor instala solo el rol que le toca (scripts/instalar_*.sh); la imagen es la misma para todos.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive TZ=America/La_Paz
RUN printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d \
 && echo "postfix postfix/main_mailer_type select No configuration" | debconf-set-selections \
 && apt-get update && apt-get install -y --no-install-recommends \
      systemd systemd-sysv dbus tzdata ca-certificates iproute2 iputils-ping curl nano less procps rsyslog openssl \
      python3 libnss3-tools tcpdump netcat-openbsd \
      bind9 bind9-utils bind9-dnsutils \
      postfix postfix-policyd-spf-python \
      opendkim opendkim-tools opendmarc \
      dovecot-core dovecot-imapd dovecot-lmtpd dovecot-sieve \
      rspamd clamav-daemon \
      swaks bsd-mailx libnet-ssleay-perl libio-socket-ssl-perl libauthen-sasl-perl libnet-dns-perl \
 && rm -f /usr/sbin/policy-rc.d \
 && find /etc/systemd/system /lib/systemd/system -path '*.wants/*' \
      \( -name '*getty*' -o -name 'systemd-logind*' -o -name 'systemd-resolved*' \) -delete || true \
 && apt-get clean && rm -rf /var/lib/apt/lists/*
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
