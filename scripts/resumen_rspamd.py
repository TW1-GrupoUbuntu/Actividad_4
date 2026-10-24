#!/usr/bin/env python3
"""Resume la ultima decision de Rspamd cuya linea de registro contiene el patron dado (IP, remitente, etc.).
Uso (en el servidor de correo): python3 resumen_rspamd.py <patron>      ej.: python3 resumen_rspamd.py 'ip: 10.44.0.66'"""
import re, sys
patron = sys.argv[1]
ultima = None
for linea in open("/var/log/rspamd/rspamd.log", errors="replace"):
    if "rspamd_task_write_log" in linea and patron in linea:
        ultima = linea
if not ultima:
    sys.exit("sin registros para: " + patron)
ip = re.search(r"ip: ([\d.]+)", ultima).group(1)
de = re.search(r"from: <([^>]*)>", ultima).group(1)
acc = re.search(r"\(default: [A-Z] \(([^)]*)\): \[([-\d.]+)/([\d.]+)\] \[(.*?)\]\), len", ultima)
accion, puntaje, umbral, simbolos = acc.groups()
print(f"origen {ip}  remitente <{de}>  ->  accion: {accion}  puntaje: {puntaje} (spam desde 6; rechazo desde 15)")
for s in re.findall(r"([A-Z][A-Z0-9_]+)\(([-\d.]+)\)\{([^}]*)\}", simbolos):
    if float(s[1]) != 0:
        print(f"   {s[0]:<28} {s[1]:>6}   {s[2][:70]}")
