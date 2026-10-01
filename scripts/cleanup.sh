#!/usr/bin/env bash
# Borra TODO lo creado por el demo (el Resource Group completo).
# Uso: ./scripts/cleanup.sh [dev|prod]
set -euo pipefail
ENV="${1:-dev}"
az group delete --name "rg-arm-demo-${ENV}" --yes --no-wait
echo "Borrando rg-arm-demo-${ENV} en segundo plano..."
