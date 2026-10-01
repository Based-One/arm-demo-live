#!/usr/bin/env bash
# Despliega el ARM template en Azure con Azure CLI.
# Uso: ./scripts/deploy.sh [dev|prod]
set -euo pipefail

ENV="${1:-dev}"
RG="rg-arm-demo-${ENV}"
LOCATION="${LOCATION:-westus2}"

echo ">> 1. Creando Resource Group ${RG} en ${LOCATION}"
az group create --name "$RG" --location "$LOCATION" --output table

echo ">> 2. Validando el template"
az deployment group validate \
  --resource-group "$RG" \
  --template-file azuredeploy.json \
  --parameters "@parameters/${ENV}.parameters.json" \
  --output none
echo "   Template valido"

echo ">> 3. Vista previa de cambios (what-if)"
az deployment group what-if \
  --resource-group "$RG" \
  --template-file azuredeploy.json \
  --parameters "@parameters/${ENV}.parameters.json"

echo ">> 4. Desplegando"
az deployment group create \
  --name "arm-demo-$(date +%Y%m%d-%H%M%S)" \
  --resource-group "$RG" \
  --template-file azuredeploy.json \
  --parameters "@parameters/${ENV}.parameters.json" \
  --query "properties.outputs" \
  --output json
