#!/usr/bin/env bash
# Se ejecuta DENTRO de "cliente" y "externo": confian en la CA del laboratorio.
cp /compartido/ca/ca.crt /usr/local/share/ca-certificates/ca-act4.crt && update-ca-certificates >/dev/null 2>&1 && echo "CA instalada en $(hostname)"
