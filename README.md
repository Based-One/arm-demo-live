# ARM Templates: Infrastructure as Code en Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FTU_USUARIO%2Farm-template-demo%2Fmain%2Fazuredeploy.json)

> Reemplaza `TU_USUARIO` por tu usuario de GitHub en este README y en `parameters/*.json`.

Este repo es un ejemplo funcional: **un solo archivo JSON** (`azuredeploy.json`) crea en Azure un Storage Account, un App Service Plan y una Web App, y además publica en la Web App el `index.html` de este mismo repositorio.

---

## Parte 1: el concepto

### ¿Qué es Infrastructure as Code (IaC)?

Es **describir tu infraestructura (servidores, bases de datos, redes, storage) en archivos de código** en lugar de crearla a mano con clics en el portal.

| A mano (portal, clics) | Infrastructure as Code |
|---|---|
| Lento y repetitivo | Un comando crea todo |
| Fácil equivocarse ("¿qué opción marqué?") | Siempre sale igual |
| No hay historial de cambios | Versionado en Git (quién cambió qué y cuándo) |
| Difícil replicar dev / test / prod | Mismo archivo, distintos parámetros |
| Si se borra, hay que recordar todo | Se recrea en minutos |

Analogía: el portal es cocinar "a ojo"; IaC es **una receta escrita**. Cualquiera la sigue y le sale el mismo platillo.

### Dos estilos de IaC

- **Imperativo**: dices *cómo* hacerlo, paso por paso (`crea esto`, `luego esto`, `luego configura aquello`). Ejemplo: un script de Azure CLI.
- **Declarativo**: dices *qué* quieres al final ("quiero una web app y un storage") y la plataforma decide cómo llegar ahí. **ARM templates son declarativos.**

### ¿Qué es ARM?

**ARM = Azure Resource Manager.** Es el servicio de Azure por el que pasa *todo*: cuando creas algo desde el portal, la CLI, PowerShell o la API, la petición llega a Resource Manager, que autentica, autoriza y le pide al proveedor correspondiente (`Microsoft.Web`, `Microsoft.Storage`, etc.) que cree el recurso.

Un **ARM template** es un archivo **JSON** que le entregas a Resource Manager describiendo los recursos que quieres. Resource Manager lo lee y crea/actualiza todo.

```
 Tú (azuredeploy.json)
        │
        ▼
 Azure Resource Manager  ── valida, ordena dependencias, despliega en paralelo
        │
   ┌────┼──────────────┐
   ▼    ▼              ▼
Storage  App Service   Web App ...
```

### ¿Qué hace en realidad? (lo importante)

1. **Valida** el JSON antes de tocar nada (tipos, valores permitidos, sintaxis).
2. **Resuelve dependencias**: sabe que la Web App necesita el Plan primero (`dependsOn`) y crea en paralelo lo que no depende entre sí.
3. **Es idempotente**: si lo despliegas 1 o 10 veces, el resultado es el mismo. Si el recurso ya existe y está igual, no hace nada; si cambiaste algo, solo actualiza eso.
4. **Guarda un historial** de despliegues en el Resource Group (pestaña *Deployments* en el portal).
5. **Modos de despliegue**:
   - *Incremental* (por defecto): agrega/actualiza lo del template, no toca lo demás.
   - *Complete*: deja el Resource Group **exactamente** como dice el template (borra lo que no esté). Cuidado.
6. **What-if**: te muestra qué va a crear, cambiar o borrar *antes* de hacerlo (como un "preview").

### Estructura de un ARM template

```json
{
  "$schema": "...",          // versión del formato
  "contentVersion": "1.0.0.0",// tu versión del template
  "parameters": { },         // valores que cambian en cada despliegue (nombre, ambiente, tamaño)
  "variables":  { },         // valores calculados dentro del template (nombres únicos, tags)
  "resources":  [ ],         // LO IMPORTANTE: los recursos de Azure a crear
  "outputs":    { }          // lo que devuelve al terminar (ej. la URL de la web)
}
```

- **parameters**: como los argumentos de una función. Pueden tener `defaultValue`, `allowedValues`, `minLength`...
- **variables**: como variables locales. Aquí se usa `uniqueString(resourceGroup().id)` para que los nombres no choquen con los de nadie más en el mundo.
- **resources**: cada uno tiene `type` (qué es), `apiVersion`, `name`, `location` y `properties`.
- **outputs**: datos útiles al final.
- **Funciones**: todo lo que está entre `[ ]` es una expresión: `[parameters('x')]`, `[variables('y')]`, `[resourceId(...)]`, `[reference(...)]`, `[format(...)]`, `[uniqueString(...)]`.

### ¿Y Bicep?

**Bicep** es un lenguaje más corto y legible que **se compila a ARM JSON**. Es el mismo motor (Resource Manager). Microsoft hoy recomienda Bicep para proyectos nuevos, pero entender ARM JSON es la base. (`az bicep decompile --file azuredeploy.json` convierte este template a Bicep.) Terraform es la alternativa multi-nube de otra empresa (HashiCorp).

---

## Parte 2: este ejemplo

```
arm-template-demo/
├── azuredeploy.json              ← el ARM template (la infraestructura)
├── parameters/
│   ├── dev.parameters.json       ← valores para desarrollo (F1, gratis)
│   └── prod.parameters.json      ← valores para producción (B1, de paga)
├── index.html                    ← la página que se publica en la Web App
└── scripts/
    ├── deploy.sh                 ← despliegue con Azure CLI (Linux/Mac/Cloud Shell)
    ├── deploy.ps1                ← despliegue con PowerShell (Windows)
    └── cleanup.sh                ← borra todo
```

Qué crea `azuredeploy.json`:

| Recurso | Tipo | Para qué |
|---|---|---|
| Storage Account | `Microsoft.Storage/storageAccounts` | Almacenamiento (StorageV2, LRS, solo HTTPS, TLS 1.2) |
| App Service Plan | `Microsoft.Web/serverfarms` | El "servidor" donde corre la web (F1 = gratis) |
| Web App | `Microsoft.Web/sites` | La aplicación web con HTTPS obligatorio |
| Source control | `Microsoft.Web/sites/sourcecontrols` | Jala `index.html` de este repo de GitHub (solo si das `repoUrl`) |

Lo que demuestra:
- `parameters` con `allowedValues` y `defaultValue`
- `variables` con `uniqueString` para nombres únicos
- `dependsOn` (la Web App espera al Plan)
- `condition` (el despliegue de código es opcional)
- `outputs` (devuelve la URL de la web)
- Mismo template, dos ambientes (dev/prod) solo cambiando el archivo de parámetros

---

## Parte 3: implementación paso a paso

### Requisitos
- Una suscripción de Azure (Azure for Students sirve).
- Este repo **público** en GitHub.
- Una de estas: el navegador (Cloud Shell), o Azure CLI instalada (`az`).

### Paso 0: Subir el repo a GitHub
1. Crea un repo público llamado `arm-template-demo` en GitHub.
2. Cambia `TU_USUARIO` en `README.md` y en `parameters/*.json` por tu usuario.
3. Sube los archivos:
   ```bash
   git remote add origin https://github.com/TU_USUARIO/arm-template-demo.git
   git push -u origin main
   ```

### Opción A: Azure CLI / Cloud Shell (la recomendada para el live demo)

```bash
# 1. Iniciar sesión (en Cloud Shell no hace falta)
az login

# 2. Crear el Resource Group (la "carpeta" donde vivirán los recursos)
az group create --name rg-arm-demo-dev --location westus2

# 3. Validar el template (no crea nada)
az deployment group validate \
  --resource-group rg-arm-demo-dev \
  --template-file azuredeploy.json \
  --parameters @parameters/dev.parameters.json

# 4. Ver qué va a pasar (what-if)
az deployment group what-if \
  --resource-group rg-arm-demo-dev \
  --template-file azuredeploy.json \
  --parameters @parameters/dev.parameters.json

# 5. Desplegar
az deployment group create \
  --resource-group rg-arm-demo-dev \
  --template-file azuredeploy.json \
  --parameters @parameters/dev.parameters.json
```

O todo junto: `./scripts/deploy.sh dev`

Al terminar, en `outputs` sale `webAppUrl`. Ábrela en el navegador y verás la página.

> En Cloud Shell (ícono `>_` arriba en el portal): `git clone https://github.com/TU_USUARIO/arm-template-demo && cd arm-template-demo && ./scripts/deploy.sh dev`

### Opción B: Portal de Azure (sin instalar nada)
1. Portal → busca **"Deploy a custom template"**.
2. **Build your own template in the editor** → pega el contenido de `azuredeploy.json` → **Save**.
3. Elige suscripción, crea el Resource Group `rg-arm-demo-dev`, llena `Repo Url` con la URL de tu repo.
4. **Review + create** → **Create**.
5. Al terminar: **Outputs** → copia `webAppUrl`.

### Opción C: Botón "Deploy to Azure"
El botón al inicio de este README abre el portal con el template ya cargado desde GitHub. Solo llenas los parámetros y das **Create**.

### Paso final: Comprobar
- Portal → Resource Group `rg-arm-demo-dev` → ves los 3 recursos con sus **tags**.
- Pestaña **Deployments** → historial del despliegue, con entradas y salidas.
- Abre `webAppUrl`.

### Demostrar la idempotencia y los cambios
1. Corre el mismo `az deployment group create` otra vez → termina sin crear nada nuevo.
2. Edita el template (por ejemplo, agrega un tag `"owner": "tu-nombre"` en `variables.tags`), corre `what-if` → muestra solo ese cambio en amarillo (`~ Modify`). Despliega.

### Limpiar (para no gastar crédito)
```bash
az group delete --name rg-arm-demo-dev --yes --no-wait
# o ./scripts/cleanup.sh dev
```

---

## Problemas comunes

| Error | Solución |
|---|---|
| `AuthorizationFailed` | Estás en otra cuenta/suscripción. `az login` y `az account set --subscription "Azure for Students"` |
| `RequestDisallowedByPolicy` (región) | Tu suscripción solo permite ciertas regiones. Prueba `eastus`, `centralus`, `westus2`, `southcentralus` |
| Ya tienes un plan F1 en esa región | Usa otra región o borra el plan anterior |
| La página muestra la bienvenida de Azure y no el index.html | El repo no es público, `repoUrl` está mal o la rama no es `main`. Espera 1-2 min y recarga |
| `StorageAccountAlreadyTaken` | Cambia `projectName` |

## Referencias
- [ARM templates overview (Microsoft Learn)](https://learn.microsoft.com/azure/azure-resource-manager/templates/overview)
- [Estructura y sintaxis de un template](https://learn.microsoft.com/azure/azure-resource-manager/templates/syntax)
- [What-if](https://learn.microsoft.com/azure/azure-resource-manager/templates/deploy-what-if)
- [Azure Quickstart Templates](https://github.com/Azure/azure-quickstart-templates)
