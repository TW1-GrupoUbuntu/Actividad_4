#!/usr/bin/env bash
# Se ejecuta DENTRO de "cliente": crea un perfil de Thunderbird para un usuario del dominio de laboratorio.
# Uso: bash perfil_thunderbird.sh <usuario> "<Nombre completo>"     (ej.: bash perfil_thunderbird.sh ana "Ana Rojas")
# Configura IMAP sobre TLS (993, SSL/TLS) y SMTP de envio (587, STARTTLS) con la CA del laboratorio en confianza.
set -e
U=${1:?usuario}; N=${2:?nombre}; DOM=horizonte.internal
PERFIL=/root/tb-$U
rm -rf "$PERFIL"; mkdir -p "$PERFIL"
cat > "$PERFIL/user.js" <<EOF
user_pref("mail.accountmanager.accounts", "account1");
user_pref("mail.accountmanager.defaultaccount", "account1");
user_pref("mail.accountmanager.localfoldersserver", "server2");
user_pref("mail.account.account1.identities", "id1");
user_pref("mail.account.account1.server", "server1");
user_pref("mail.account.account2.server", "server2");
user_pref("mail.identity.id1.fullName", "$N");
user_pref("mail.identity.id1.useremail", "$U@$DOM");
user_pref("mail.identity.id1.smtpServer", "smtp1");
user_pref("mail.identity.id1.valid", true);
user_pref("mail.server.server1.type", "imap");
user_pref("mail.server.server1.hostname", "mail.$DOM");
user_pref("mail.server.server1.port", 993);
user_pref("mail.server.server1.userName", "$U");
user_pref("mail.server.server1.socketType", 3);
user_pref("mail.server.server1.authMethod", 3);
user_pref("mail.server.server1.name", "$U@$DOM");
user_pref("mail.server.server1.check_new_mail", true);
user_pref("mail.server.server2.type", "none");
user_pref("mail.server.server2.hostname", "Local Folders");
user_pref("mail.server.server2.userName", "nobody");
user_pref("mail.smtpservers", "smtp1");
user_pref("mail.smtp.defaultserver", "smtp1");
user_pref("mail.smtpserver.smtp1.hostname", "mail.$DOM");
user_pref("mail.smtpserver.smtp1.port", 587);
user_pref("mail.smtpserver.smtp1.username", "$U");
user_pref("mail.smtpserver.smtp1.try_ssl", 2);
user_pref("mail.smtpserver.smtp1.authMethod", 3);
user_pref("mail.provider.suppress_dialog_on_startup", true);
user_pref("mail.shell.checkDefaultClient", false);
user_pref("mail.rights.version", 1);
user_pref("mailnews.start_page.enabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.policy.firstRunURL", "");
user_pref("app.update.enabled", false);
user_pref("app.update.auto", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("mail.spotlight.firstRunDone", true);
user_pref("mail.winsearch.firstRunDone", true);
user_pref("mail.chat.enabled", false);
user_pref("mail.openpgp.enable", false);
user_pref("mail.biff.show_alert", false);
user_pref("mail.default_charsets.sent_mail", "UTF-8");
user_pref("mail.compose.attachment_reminder", false);
user_pref("mailnews.default_sort_order", 2);
user_pref("mailnews.default_sort_type", 18);
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("extensions.autoDisableScopes", 0);
user_pref("mail.imap.use_status_for_biff", false);
user_pref("layout.css.devPixelsPerPx", "1.0");
EOF
# La CA del laboratorio en el almacen de certificados del perfil (para que no pida confirmar el certificado del servidor)
certutil -N -d sql:"$PERFIL" --empty-password
certutil -A -d sql:"$PERFIL" -n "CA del laboratorio de correo" -t "CT,," -i /compartido/ca/ca.crt
echo "perfil de $U listo en $PERFIL"
