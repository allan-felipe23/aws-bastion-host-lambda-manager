# Busca a AMI mais recente do Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "bastion" {
  ami             = data.aws_ami.amazon_linux_2023.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.bastion_sg.id]

  # ATENÇÃO: Para acessar a máquina você precisa definir um key_name aqui 
  # correspondente a uma chave PEM existente na sua conta AWS.
  # key_name = "sua-chave-ssh"

  tags = {
    Name = "Bastion-Host"
  }
}

# Subnet group do Banco de Dados
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# Instância do RDS (PostgreSQL)
resource "aws_db_instance" "rds" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  db_name                = "meubanco"
  username               = "adminuser"
  password               = "senha_super_secreta_123" # Em prod, use Secrets Manager!
  skip_final_snapshot    = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}
