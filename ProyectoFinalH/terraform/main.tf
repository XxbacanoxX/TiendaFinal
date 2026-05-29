# ==============================================================================
# CREDENCIALES AWS — CONFIGURA AQUÍ O COMO VARIABLES DE ENTORNO
# ==============================================================================
# OPCIÓN A (Recomendada para AWS Academy / Learner Lab):
#   Ejecuta estos comandos en PowerShell ANTES de hacer terraform apply:
#
#   $env:AWS_ACCESS_KEY_ID     = "TU_ACCESS_KEY_ID_AQUI"
#   $env:AWS_SECRET_ACCESS_KEY = "TU_SECRET_ACCESS_KEY_AQUI"
#   $env:AWS_SESSION_TOKEN     = "TU_SESSION_TOKEN_AQUI"
#   $env:AWS_DEFAULT_REGION    = "us-east-1"
#
# OPCIÓN B (Credenciales directas en el provider — NO recomendado para git):
#   Descomenta las líneas access_key / secret_key / token del bloque provider
#   que está abajo y reemplaza los valores.
# ==============================================================================

provider "aws" {
  region = var.aws_region

  # ── DESCOMENTA Y RELLENA SOLO SI USAS LA OPCIÓN B ──────────────────────────
  # access_key = "TU_AWS_ACCESS_KEY_ID_AQUI"       # <-- TU ACCESS KEY
  # secret_key = "TU_AWS_SECRET_ACCESS_KEY_AQUI"   # <-- TU SECRET KEY
  # token      = "TU_AWS_SESSION_TOKEN_AQUI"        # <-- TU SESSION TOKEN (solo AWS Academy)
  # ---------------------------------------------------------------------------
}

# ── AMI más reciente de Amazon Linux 2023 ────────────────────────────────────
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# ── Security Group ────────────────────────────────────────────────────────────
resource "aws_security_group" "store_sg" {
  name        = "${var.project_name}-sg"
  description = "SG para store + Prometheus + Grafana"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "store Web App"
    from_port   = var.store_port
    to_port     = var.store_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Grafana"
    from_port   = var.grafana_port
    to_port     = var.grafana_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Prometheus"
    from_port   = var.prometheus_port
    to_port     = var.prometheus_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

# ── EC2 Instance ──────────────────────────────────────────────────────────────
resource "aws_instance" "store_server" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.store_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # gzip + base64: el script es ~19KB, supera el límite de 16KB de EC2.
  # base64gzip() comprime primero y EC2 descomprime automáticamente al arrancar.
  user_data_base64 = base64gzip(file("${path.module}/user_data.sh"))

  tags = {
    Name    = "${var.project_name}-server"
    Project = var.project_name
  }
}
