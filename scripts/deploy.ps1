# Despliega el ARM template con Azure PowerShell (Windows).
# Uso: ./scripts/deploy.ps1 -Environment dev
param(
  [ValidateSet("dev", "prod")] [string] $Environment = "dev",
  [string] $Location = "westus2"
)

$rg = "rg-arm-demo-$Environment"

New-AzResourceGroup -Name $rg -Location $Location -Force

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
  -TemplateFile ./azuredeploy.json `
  -TemplateParameterFile "./parameters/$Environment.parameters.json"

New-AzResourceGroupDeployment -ResourceGroupName $rg `
  -TemplateFile ./azuredeploy.json `
  -TemplateParameterFile "./parameters/$Environment.parameters.json" `
  -WhatIf

New-AzResourceGroupDeployment -ResourceGroupName $rg `
  -Name "arm-demo-$(Get-Date -Format yyyyMMdd-HHmmss)" `
  -TemplateFile ./azuredeploy.json `
  -TemplateParameterFile "./parameters/$Environment.parameters.json"
