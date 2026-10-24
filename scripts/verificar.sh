#!/usr/bin/env bash
# Verificador de la Actividad 4. Se ejecuta DENTRO de "cliente":
#   docker exec -w /lab act4-cliente bash scripts/verificar.sh
# Comprueba DNS (MX, SPF, DKIM, DMARC, PTR), TLS en SMTP e IMAP, relé cerrado, envio y recepcion entre buzones y antispam/antivirus.
NS=10.44.0.2; H=horizonte.internal; F=familia.internal
P=$(cat /compartido/clave_buzones)
bien=0; total=0
prueba() { total=$((total + 1)); if bash -c "$2" >/dev/null 2>&1; then echo "✅ $1"; bien=$((bien + 1)); else echo "❌ $1"; fi; }
q() { dig +short @$NS "$@"; }
export -f q; export NS
seccion() { echo; echo "── $1"; }

seccion "DNS (zona publicada y verificada con dig)"
prueba "MX de $H -> mail.$H" "q $H MX | grep -q 'mail.$H.'"
prueba "MX de $F -> mail.$F" "q $F MX | grep -q 'mail.$F.'"
prueba "SPF de $H (-all)" "q $H TXT | grep -q 'v=spf1 mx -all'"
prueba "SPF de $F (-all)" "q $F TXT | grep -q 'v=spf1 mx -all'"
prueba "DKIM de $H (mail._domainkey, 2048 bits)" "q mail._domainkey.$H TXT | tr -d '\" ' | grep -q 'v=DKIM1' && [ \$(q mail._domainkey.$H TXT | tr -d '\" ' | grep -o 'p=[A-Za-z0-9+/=]*' | wc -c) -gt 380 ]"
prueba "DKIM de $F (mail._domainkey)" "q mail._domainkey.$F TXT | tr -d '\" ' | grep -q 'v=DKIM1'"
prueba "DMARC de $H (quarantine, alineacion estricta)" "q _dmarc.$H TXT | grep -q 'p=quarantine.*adkim=s; aspf=s'"
prueba "DMARC de $F (quarantine)" "q _dmarc.$F TXT | grep -q 'p=quarantine'"
prueba "PTR de 10.44.0.25 -> mail.$H" "q -x 10.44.0.25 | grep -q 'mail.$H.'"
prueba "Autodescubrimiento SRV de IMAPS y submission" "q _imaps._tcp.$H SRV | grep -q 993 && q _submission._tcp.$H SRV | grep -q 587"

seccion "Cifrado en SMTP e IMAP"
prueba "SMTP 25 ofrece STARTTLS con certificado valido (CA propia, TLS >= 1.2)" "echo | openssl s_client -starttls smtp -connect mail.$H:25 -verify_return_error -CAfile /compartido/ca/ca.crt -verify_hostname mail.$H 2>&1 | grep -qE 'Verification: OK|Verify return code: 0'"
prueba "Submission 587 con TLS valido" "echo | openssl s_client -starttls smtp -connect mail.$H:587 -verify_return_error -CAfile /compartido/ca/ca.crt -verify_hostname mail.$H 2>&1 | grep -qE 'Verification: OK|Verify return code: 0'"
prueba "IMAPS 993 con certificado valido" "echo | openssl s_client -connect mail.$H:993 -verify_return_error -CAfile /compartido/ca/ca.crt -verify_hostname mail.$H 2>&1 | grep -qE 'Verification: OK|Verify return code: 0'"
prueba "IMAP en claro (143) cerrado" "! nc -z -w 3 mail.$H 143"
prueba "Submission rechaza el envio sin autenticar" "swaks --to luis@$H --from ana@$H --server mail.$H --port 587 --tls 2>&1 | grep -qE '^<[-~]\*? +(530|503|554)'"

seccion "Relé abierto descartado"
prueba "Un tercero no puede relayar a un dominio externo (554 Relay access denied)" "swaks --to victima@gmail.test --from falso@$H --server mail.$H --quit-after RCPT 2>&1 | grep -q '554 5.7.1'"
prueba "Tampoco desde un nodo ajeno (externo) hacia otro dominio (mail2)" "swaks --to alguien@otro.example --from falso@$F --server mail.$F --quit-after RCPT 2>&1 | grep -q '554 5.7.1'"

seccion "Envio y recepcion entre buzones (587 con TLS + IMAPS)"
ASU="Prueba-$(date +%s)"
prueba "ana -> luis (mismo dominio, 587 + AUTH)" "swaks --to luis@$H --from ana@$H --server mail.$H --port 587 --tls --auth-user ana --auth-password '$P' --header 'Subject: $ASU' --body 'Prueba de la Actividad 4' 2>&1 | grep -qE '^<[-~]\*? +250 2.0.0 Ok'"
sleep 3
prueba "luis recibe el correo por IMAPS" "python3 /lab/scripts/leer_buzon.py mail.$H luis INBOX listar $ASU | grep -q '$ASU'"
prueba "ana (remitente falso: luis) es rechazada por reject_sender_login_mismatch" "swaks --to luis@$H --from luis@$H --server mail.$H --port 587 --tls --auth-user ana --auth-password '$P' --quit-after RCPT 2>&1 | grep -qE '^<[-~]\*? +553 5.7.1'"
ASU2="Entre-dominios-$(date +%s)"
prueba "ana -> rosa (otro dominio: familia.internal)" "swaks --to rosa@$F --from ana@$H --server mail.$H --port 587 --tls --auth-user ana --auth-password '$P' --header 'Subject: $ASU2' --body 'Correo entre dominios' 2>&1 | grep -qE '^<[-~]\*? +250 2.0.0 Ok'"
sleep 4
prueba "rosa recibe el correo por IMAPS" "python3 /lab/scripts/leer_buzon.py mail.$F rosa INBOX listar $ASU2 | grep -q '$ASU2'"
prueba "El correo llega con dkim=pass y SPF pass" "python3 /lab/scripts/leer_buzon.py mail.$F rosa INBOX cabeceras $ASU2 | grep -E '^Authentication-Results' | grep -q 'dkim=pass' && python3 /lab/scripts/leer_buzon.py mail.$F rosa INBOX cabeceras $ASU2 | grep -E '^Received-SPF' | grep -qi 'pass'"
prueba "El correo llega con dmarc=pass" "python3 /lab/scripts/leer_buzon.py mail.$F rosa INBOX cabeceras $ASU2 | grep -E '^Authentication-Results' | grep -q 'dmarc=pass'"

seccion "Antispam y antivirus (Rspamd + ClamAV)"
GT='XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X'
prueba "Rspamd rechaza la cadena de prueba de spam GTUBE (554)" "swaks --to luis@$H --from rosa@$F --server mail.$H --body '$GT' 2>&1 | grep -qE '^<[-*~]+ +554'"
printf '%s' 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /tmp/eicar.com
prueba "ClamAV bloquea un adjunto con el virus de prueba EICAR (554 virus found)" "swaks --to luis@$H --from rosa@$F --server mail.$H --attach-type application/octet-stream --attach-name eicar.com --attach @/tmp/eicar.com 2>&1 | grep -qE '^<[-*~]+ +554.*Eicar'"

echo
echo "Resultado: $bien de $total comprobaciones correctas"
echo "Actividad 4 - correo institucional"
[ "$bien" -eq "$total" ]
