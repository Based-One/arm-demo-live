# Guía para presentar (live example + repo)

El profe pide: **1) un ejemplo en vivo** y **2) el repo público en GitHub**. Así se cumplen los dos: muestras el repo, y desde ese repo despliegas en vivo a Azure.

## Antes de la clase (no lo dejes para el momento)
- [ ] Repo público en GitHub con `TU_USUARIO` reemplazado.
- [ ] Hacer el despliegue **una vez completo** de prueba para confirmar que funciona en tu suscripción y región. Luego bórralo (o déjalo como respaldo).
- [ ] Tener abiertas pestañas: GitHub (repo), Portal de Azure, Cloud Shell o terminal con `az login` hecho.
- [ ] Tener la URL del despliegue de prueba a mano por si el internet falla (plan B: capturas de pantalla).
- [ ] Letra de la terminal grande (Ctrl + +).

## Guion (unos 10 min)

**1. Problema (1 min)**
"Crear infraestructura a mano en el portal es lento, no se puede repetir igual y no queda historial. ¿Cómo creo dev y prod idénticos? → Infrastructure as Code."

**2. Concepto (2-3 min)** (usa la Parte 1 del README)
- IaC = la infraestructura descrita en archivos y guardada en Git.
- Declarativo vs. imperativo.
- ARM = Azure Resource Manager; un ARM template es el JSON que le das.
- Lo que hace: valida, resuelve dependencias, idempotente, what-if, historial.

**3. Recorrido por el repo en GitHub (2 min)**
Abre `azuredeploy.json` en GitHub y señala:
- `parameters` → "lo que cambia entre despliegues" (enseña `allowedValues` de F1/B1).
- `variables` → `uniqueString` para nombres únicos.
- `resources` → los 4 recursos; señala `dependsOn` y `condition`.
- `outputs` → la URL.
- Carpeta `parameters/` → "mismo template, dev y prod".

**4. Live demo (3-4 min)**
```bash
az group create -n rg-arm-demo-dev -l westus2
az deployment group what-if -g rg-arm-demo-dev --template-file azuredeploy.json --parameters @parameters/dev.parameters.json
az deployment group create  -g rg-arm-demo-dev --template-file azuredeploy.json --parameters @parameters/dev.parameters.json
```
- Mientras despliega (1-2 min): Portal → Resource Group → **Deployments** y ve cómo aparecen los recursos.
- Abre `webAppUrl` → aparece la página del repo.
- **Momento clave**: vuelve a correr el `create` → "no creó nada nuevo: es idempotente".
- (Opcional) agrega un tag, corre `what-if` → muestra solo el cambio.

**5. Cierre (1 min)**
- Ventajas: repetible, versionado, revisable, automatizable (CI/CD con GitHub Actions).
- Mencionar Bicep como la evolución (compila a ARM).
- `az group delete -n rg-arm-demo-dev --yes --no-wait` frente a ellos → "y con esto se borra todo; el archivo lo vuelve a crear cuando quiera".

## Preguntas que te pueden hacer
- **¿Diferencia con un script de Azure CLI?** El script es imperativo: si lo corres dos veces puede fallar o duplicar. El template es declarativo e idempotente.
- **¿Qué pasa si borro un recurso del template y vuelvo a desplegar?** En modo *Incremental* (default) el recurso sigue existiendo. En modo *Complete* se borra.
- **¿ARM vs. Bicep vs. Terraform?** ARM = JSON nativo de Azure. Bicep = sintaxis más simple que se compila a ARM. Terraform = herramienta de HashiCorp, multi-nube, guarda un archivo de estado.
- **¿Por qué `uniqueString`?** Storage y Web Apps necesitan nombres únicos globalmente; genera un sufijo estable basado en el ID del Resource Group.
- **¿Qué es `dependsOn`?** Le dice a ARM el orden: la Web App necesita que el Plan exista primero. Lo demás se crea en paralelo.
- **¿Cuánto cuesta?** Con F1 y Storage vacío, prácticamente $0.
