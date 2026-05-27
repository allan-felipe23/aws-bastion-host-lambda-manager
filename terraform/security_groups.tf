# SG do Bastion Host
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Permite acesso SSH ao Bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH do meu IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.meu_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG do RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Permite acesso ao banco de dados pelo Bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL acesso vindo do Bastion"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
