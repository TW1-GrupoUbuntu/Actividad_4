#!/usr/bin/env bash
# Elimina contenedores, red y volumenes de la Actividad 4 (no toca nada mas).
cd "$(dirname "$0")/.." && docker compose -p act4 down -v --remove-orphans
