import boto3
import os
import logging

# Configuração de Logs para o CloudWatch
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Inicializa o client do EC2
ec2_client = boto3.client('ec2')

def lambda_handler(event, context):
    """
    Função Lambda para iniciar ou parar uma instância EC2 (Bastion Host)
    
    O evento recebido (via EventBridge) deve conter a estrutura:
    {
      "action": "start" ou "stop",
      "instance_id": "i-0123456789abcdef0"
    }
    """
    try:
        # Pega a ação a partir do evento do EventBridge
        action = event.get('action')
        
        # O ID da instância pode vir no payload do EventBridge ou via Variável de Ambiente
        instance_id = event.get('instance_id') or os.environ.get('INSTANCE_ID')
        
        if not action or action not in ['start', 'stop']:
            logger.error("Ação inválida ou não informada. Use: 'start' ou 'stop'.")
            return {
                'statusCode': 400,
                'body': 'Ação inválida.'
            }
            
        if not instance_id:
            logger.error("ID da instância não informado.")
            return {
                'statusCode': 400,
                'body': 'Instance ID não informado.'
            }
        
        # Executa a ação
        if action == 'start':
            logger.info(f"Iniciando a instância EC2: {instance_id}")
            ec2_client.start_instances(InstanceIds=[instance_id])
            message = f"Instância {instance_id} ligada com sucesso."
            
        elif action == 'stop':
            logger.info(f"Parando a instância EC2: {instance_id}")
            ec2_client.stop_instances(InstanceIds=[instance_id])
            message = f"Instância {instance_id} desligada com sucesso."
            
        logger.info(message)
        return {
            'statusCode': 200,
            'body': message
        }
        
    except Exception as e:
        logger.error(f"Erro ao processar a solicitação: {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Erro: {str(e)}"
        }
