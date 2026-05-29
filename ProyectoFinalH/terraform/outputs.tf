output "instance_public_ip" {
  description = "IP pública de la instancia EC2"
  value       = aws_instance.store_server.public_ip
}

output "store_url" {
  description = "URL del store"
  value       = "http://${aws_instance.store_server.public_ip}:25000"
}

output "grafana_url" {
  description = "URL de Grafana (usuario: hectorespinosa / contraseña: hsel)"
  value       = "http://${aws_instance.store_server.public_ip}:25030"
}

output "prometheus_url" {
  description = "URL de Prometheus"
  value       = "http://${aws_instance.store_server.public_ip}:25090"
}

output "ssh_command" {
  description = "Comando SSH para conectarse a la instancia"
  value       = "ssh -i vockey.pem ec2-user@${aws_instance.store_server.public_ip}"
}

output "setup_time_note" {
  description = "Nota sobre el tiempo de arranque"
  value       = "La app tarda ~8 minutos en estar lista después de 'terraform apply'. Revisa logs con: ssh -i vockey.pem ec2-user@${aws_instance.store_server.public_ip} 'sudo tail -f /var/log/user-data.log'"
}
