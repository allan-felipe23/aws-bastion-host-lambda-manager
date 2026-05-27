provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados"
  default     = "us-east-1"
}

variable "meu_ip" {
  description = "Seu IP público para acessar o Bastion Host via SSH (Ex: 203.0.113.50/32)"
  default     = "0.0.0.0/0" # Substitua pelo seu IP real por segurança!
}
