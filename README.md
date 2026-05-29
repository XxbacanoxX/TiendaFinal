# TiendaFinal

# NexusKeys — Tienda de Juegos Web con Monitoreo (Flask + Prometheus + Grafana)

Tienda de juegos digitales completa en el navegador con un stack de monitoreo automático. Este proyecto ha sido diseñado para ser aprovisionado y desplegado de forma **100% automática en AWS usando Terraform**.

---

## Configurar Credenciales AWS (PASO OBLIGATORIO)

> [!IMPORTANT]
> Antes de cualquier comando de Terraform debes configurar tus credenciales de AWS.
> Encuéntralas en **AWS Academy -> Learner Lab -> "AWS Details" -> botón "Show"**.

### Opción A — Variables de entorno en PowerShell (recomendada)

$env:AWS_ACCESS_KEY_ID     = "TU_AWS_ACCESS_KEY_ID_AQUI"
$env:AWS_SECRET_ACCESS_KEY = "TU_AWS_SECRET_ACCESS_KEY_AQUI"
$env:AWS_SESSION_TOKEN     = "TU_AWS_SESSION_TOKEN_AQUI"
$env:AWS_DEFAULT_REGION    = "us-east-1"

También puedes usar el script incluido:

# 1. Copia el archivo de ejemplo
Copy-Item set_credentials.example.ps1 set_credentials.ps1

# 2. Edita set_credentials.ps1 con tus credenciales reales

# 3. Ejecútalo
.\set_credentials.ps1

### Opción B — Directamente en el provider de Terraform

Abre terraform/main.tf y descomenta/rellena las líneas marcadas con <-- TU ...:

provider "aws" {
  region     = var.aws_region
  access_key = "TU_AWS_ACCESS_KEY_ID_AQUI"
  secret_key = "TU_AWS_SECRET_ACCESS_KEY_AQUI"
  token      = "TU_AWS_SESSION_TOKEN_AQUI"
}

> [!WARNING]
> No hagas commit del archivo main.tf con las credenciales en texto plano. La Opción A es más segura.

---

## Despliegue Automático en AWS

La infraestructura se despliega de forma totalmente autónoma en la región us-east-1 (Norte de Virginia), compatible con el Key Pair predeterminado (vockey) y las credenciales temporales de AWS Academy (Learner Labs / voclabs).

### Arquitectura Desplegada

* Instancia EC2 (t2.medium): Con disco de 30 GB (gp3)
* Security Group: Expone solo los puertos necesarios:
  * 25000 -> Aplicación Web de la Tienda (Flask)
  * 25030 -> Dashboard de Grafana
  * 25090 -> Prometheus
  * 22   -> Acceso SSH
* User Data Autónomo: Instala Docker, construye los contenedores y levanta los 5 servicios automáticamente.

---

### Instrucciones de Despliegue (Paso a Paso)

#### 1. Configurar credenciales AWS
Ver sección anterior.

#### 2. Inicializar y aplicar la infraestructura

cd terraform
terraform init
terraform apply -auto-approve

#### 3. Verificar los outputs

Outputs:
  instance_public_ip = "X.X.X.X"
  store_url          = "http://X.X.X.X:25000"
  grafana_url        = "http://X.X.X.X:25030"
  prometheus_url     = "http://X.X.X.X:25090"
  ssh_command        = "ssh -i vockey.pem ec2-user@X.X.X.X"

> [!IMPORTANT]
> Tiempo de arranque: Una vez que Terraform finaliza, la instancia tarda entre 5 y 8 minutos en levantar todos los servicios. Monitorea con:
> ssh -i vockey.pem ec2-user@<IP> 'sudo tail -f /var/log/user-data.log'

---

### Limpieza de Recursos

terraform destroy -auto-approve

---

## Estructura del Proyecto

NexusKeys/
├── set_credentials.example.ps1   <- Plantilla para configurar credenciales AWS
├── docker-compose.yml
├── frontend/
│   ├── app.py                    <- Flask: sirve la tienda y expone /metrics
│   ├── Dockerfile
│   ├── requirements.txt
│   └── templates/
│       └── index.html            <- Tienda de juegos (HTML + CSS + JS)
├── backend/
│   ├── Dockerfile
│   ├── prometheus/
│   │   └── prometheus.yml
│   └── grafana/
│       ├── dashboards/
│       │   └── store.json
│       └── provisioning/
│           ├── dashboards/
│           │   └── dashboards.yml
│           └── datasources/
│               └── prometheus.yml
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── versions.tf
    └── user_data.sh

## Servicios

| Servicio        | Descripción                                           |
|-----------------|-------------------------------------------------------|
| frontend        | Flask que sirve la tienda y expone /metrics           |
| prometheus      | Recolecta métricas cada 5 s                           |
| grafana         | Dashboard automático con estadísticas de la tienda    |
| node-exporter   | Métricas de CPU, memoria, disco y red del servidor    |
| cadvisor        | Métricas de CPU y memoria por contenedor              |

## Puertos

| URL                        | Que hay ahi                    |
|----------------------------|--------------------------------|
| http://<IP>:25000           | Tienda de juegos NexusKeys    |
| http://<IP>:25030           | Grafana (admin / root)        |
| http://<IP>:25090           | Prometheus                    |
| http://<IP>:25000/metrics   | Métricas en texto plano       |

## Métricas de la Tienda

| Métrica                          | Tipo      | Descripción                                   |
|----------------------------------|-----------|-----------------------------------------------|
| store_purchases_total            | Counter   | Compras completadas                           |
| store_revenue_total_usd          | Counter   | Ingresos acumulados en USD                    |
| store_keys_delivered_total       | Counter   | Claves digitales entregadas                   |
| store_cart_abandoned_total       | Counter   | Carritos abandonados sin comprar              |
| store_discounts_applied_total    | Counter   | Descuentos aplicados en compras               |
| store_wishlist_additions_total   | Counter   | Juegos añadidos a favoritos                   |
| store_searches_total             | Counter   | Búsquedas realizadas en la tienda             |
| store_game_sales_total           | Counter   | Ventas por nombre de juego                    |
| store_sales_by_category_total    | Counter   | Ventas por categoría (rpg, accion, etc.)      |
| store_sales_by_platform_total    | Counter   | Ventas por plataforma (PC, PlayStation, etc.) |
| store_active_users               | Gauge     | Usuarios navegando la tienda ahora mismo      |
| store_cart_items_current         | Gauge     | Items en carritos activos en este momento     |
| store_page_visits_total          | Counter   | Visitas a las páginas de la tienda            |
| store_request_latency_seconds    | Histogram | Latencia p95 de las peticiones                |

## Eventos de la API

El endpoint /api/store/event recibe los siguientes eventos desde el frontend:

| Evento         | Descripción                                     |
|----------------|-------------------------------------------------|
| user_enter     | Usuario abre la tienda                          |
| user_leave     | Usuario cierra la tienda                        |
| cart_add       | Producto añadido al carrito                     |
| cart_remove    | Producto eliminado del carrito                  |
| cart_abandon   | Carrito abandonado sin completar la compra      |
| purchase       | Compra completada (incluye precio, juego, etc.) |
| wishlist_add   | Juego añadido a favoritos                       |
| search         | Búsqueda realizada en la tienda                 |

## Comandos útiles

# Ver estado de servicios
docker compose ps

# Ver logs en tiempo real
docker compose logs -f

# Detener todo
docker compose down

# Detener y borrar volúmenes
docker compose down -v
