#!/usr/bin/env bash
# Se ejecuta DENTRO de "cliente" (tras instalar_thunderbird.sh y perfil_thunderbird.sh): maneja Thunderbird en una pantalla virtual
# de 1920x1080 con xdotool, como lo haria una persona, y guarda capturas de pantalla en /compartido/tb_*.png
#   1. Ana: inicia sesion por IMAP/TLS, muestra la configuracion de entrada (993, SSL/TLS) y de salida (587, STARTTLS), redacta y envia
#   2. Luis: inicia sesion, lee el mensaje de Ana, muestra su codigo fuente (cabeceras) y le responde
#   3. Ana: recibe la respuesta
# Las coordenadas corresponden a Thunderbird 158 en espanol a 1920x1080.
export DISPLAY=:99 HOME=/root
S=/compartido
cap() { sleep 2; import -window root "$S/$1.png"; }
clic() { xdotool mousemove "$1" "$2" click 1; sleep "${3:-2}"; }
escribir() { xdotool type --delay 70 -- "$1"; }
clave() { escribir "$(cat /compartido/clave_buzones)"; }
pgrep -x Xvfb >/dev/null || { Xvfb :99 -screen 0 1920x1080x24 >/dev/null 2>&1 & sleep 2; }

iniciar() { # iniciar <usuario>
  pkill -x thunderbird >/dev/null 2>&1; pkill -x thunderbird-bin >/dev/null 2>&1; sleep 3
  (cd /root && nohup thunderbird --profile "/root/tb-$1" --no-remote >"/tmp/tb-$1.log" 2>&1 &)
  sleep 28
  W=$(xdotool search --onlyvisible --name Thunderbird | head -n1)
  xdotool windowmove "$W" 0 0 windowsize "$W" 1920 1080; sleep 3
}
entrar() { # entrar <captura-del-dialogo> <captura-de-la-bandeja>
  clic 385 147 7; cap "$1"                 # "Leer mensajes": conecta por IMAPS y pide la contrasena
  clic 987 538 1; clave; clic 1198 600 12  # escribe la contrasena (no se guarda) y acepta
  cap "$2"
}
enviar_con_clave() { # pulsa Enviar, espera el dialogo de la contrasena SMTP, la escribe y acepta
  clic 42 44 12; cap "$1"
  clic 457 398 1; clave; clic 668 460 16
}

# ---------- 1. Ana ----------
iniciar ana
entrar tb_01_ana_pide_clave tb_02_ana_bandeja
clic 170 113 5                                  # pagina de la cuenta
clic 1790 75 7                                  # Configuracion de la cuenta
clic 195 177 9; cap tb_03_ana_servidor_entrada
clic 160 457 6; cap tb_04_ana_servidor_salida
clic 532 65 4                                   # cierra la pestana de configuracion (vuelve al correo)
clic 165 70 7                                   # Nuevo mensaje
clic 495 123 1; escribir "luis@horizonte.internal, rosa@familia.internal"
clic 495 159 1; escribir "Comunicado del lunes: acto civico"
clic 430 400 1; escribir "Estimados: el acto civico del lunes comienza a las 8:00 en el patio. Se solicita puntualidad. Ana."
sleep 2; cap tb_05_ana_redacta
enviar_con_clave tb_06_ana_pide_clave_smtp
clic 140 197 4; cap tb_07_ana_enviado        # carpeta Enviados

# ---------- 2. Luis ----------
iniciar luis
entrar tb_08_luis_pide_clave tb_09_luis_bandeja
clic 740 123 6; cap tb_10_luis_lee_mensaje      # abre el primer mensaje (el de Ana)
xdotool key ctrl+r; sleep 9                      # Responder: abre la ventana de redaccion con el mensaje citado
clic 430 600 1; xdotool key ctrl+Home; escribir "Recibido, Ana. Estare puntual en el patio. Luis."; xdotool key Return
sleep 2; cap tb_11_luis_responde
enviar_con_clave tb_12_luis_pide_clave_smtp
clic 140 197 4; cap tb_13_luis_enviado           # carpeta Enviados
clic 160 141 3; clic 740 123 4                   # vuelve a la bandeja y al mensaje de Ana
xdotool key ctrl+u; sleep 8                      # Codigo fuente del mensaje: cabeceras completas
F=$(xdotool search --onlyvisible --name "(Fuente|Source)" | head -n1); [ -n "$F" ] && xdotool windowsize "$F" 1500 950
sleep 2; cap tb_14_luis_codigo_fuente

# ---------- 3. Ana recibe la respuesta ----------
iniciar ana
entrar tb_15_ana_pide_clave_2 tb_16_ana_recibe_respuesta
clic 740 123 5; cap tb_17_ana_lee_respuesta
pkill -x thunderbird >/dev/null 2>&1; pkill -x thunderbird-bin >/dev/null 2>&1
echo FIN_THUNDERBIRD
