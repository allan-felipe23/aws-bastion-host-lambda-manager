# Lê o código python existente no repositório
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/lambda_function.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# Role do IAM para a Lambda
resource "aws_iam_role" "lambda_role" {
  name = "bastion_start_stop_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Policy da Lambda (aproveita o JSON do repositório)
resource "aws_iam_policy" "lambda_policy" {
  name        = "bastion_start_stop_policy"
  description = "Permite a lambda gerenciar EC2 e gravar logs"
  policy      = file("${path.module}/../policies/lambda_policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Função Lambda
resource "aws_lambda_function" "bastion_manager" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "BastionManager"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.10"
}

# -------------------------------------------------------------
# EVENTBRIDGE (CRON)
# -------------------------------------------------------------

# Regra para ligar às 08:00 UTC
resource "aws_cloudwatch_event_rule" "start_bastion" {
  name                = "start-bastion-rule"
  schedule_expression = "cron(0 8 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "start_bastion_target" {
  rule      = aws_cloudwatch_event_rule.start_bastion.name
  target_id = "StartBastionTarget"
  arn       = aws_lambda_function.bastion_manager.arn

  # Envia o JSON customizado para a Lambda
  input = jsonencode({
    action      = "start"
    instance_id = aws_instance.bastion.id
  })
}

# Regra para desligar às 18:00 UTC
resource "aws_cloudwatch_event_rule" "stop_bastion" {
  name                = "stop-bastion-rule"
  schedule_expression = "cron(0 18 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "stop_bastion_target" {
  rule      = aws_cloudwatch_event_rule.stop_bastion.name
  target_id = "StopBastionTarget"
  arn       = aws_lambda_function.bastion_manager.arn

  input = jsonencode({
    action      = "stop"
    instance_id = aws_instance.bastion.id
  })
}

# Permite que o EventBridge invoque a Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bastion_manager.function_name
  principal     = "events.amazonaws.com"
}
