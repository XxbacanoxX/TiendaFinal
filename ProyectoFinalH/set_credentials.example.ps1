# ==============================================================================
# CREDENCIALES AWS — LEE ESTO ANTES DE HACER terraform apply
# ==============================================================================
#
# Copia este archivo como "set_credentials.ps1" y rellena tus valores.
# Encuéntralos en AWS Academy → Learner Lab → "AWS Details" → "Show"
#
# EJECÚTALO en PowerShell ANTES de correr terraform:
#   .\set_credentials.ps1
#
# ==============================================================================

# ── PEGA AQUÍ TUS CREDENCIALES DE AWS ACADEMY ─────────────────────────────────
$env:AWS_ACCESS_KEY_ID     = "TU_AWS_ACCESS_KEY_ID_AQUI"       # <-- REEMPLAZA
$env:AWS_SECRET_ACCESS_KEY = "TU_AWS_SECRET_ACCESS_KEY_AQUI"   # <-- REEMPLAZA
$env:AWS_SESSION_TOKEN     = "TU_AWS_SESSION_TOKEN_AQUI"        # <-- REEMPLAZA (solo AWS Academy)
$env:AWS_DEFAULT_REGION    = "us-east-1"

Write-Host " Credenciales AWS configuradas para esta sesión de PowerShell." -ForegroundColor Green
Write-Host "   Ahora puedes correr: cd terraform ; terraform init ; terraform apply -auto-approve" -ForegroundColor Cyan
