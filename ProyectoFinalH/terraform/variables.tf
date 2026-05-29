variable "aws_region" {
  description = "AWS region donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.medium"
}

variable "key_name" {
  description = "Nombre del key pair en AWS EC2"
  type        = string
  default     = "vockey"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "ProyectoFinalH"
}

variable "store_port" {
  description = "Puerto de la tienda (Flask)"
  type        = number
  default     = 25000
}

variable "grafana_port" {
  description = "Puerto de Grafana"
  type        = number
  default     = 25030
}

variable "prometheus_port" {
  description = "Puerto de Prometheus"
  type        = number
  default     = 25090
}
