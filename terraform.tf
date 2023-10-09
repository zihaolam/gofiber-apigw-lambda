provider "aws" {
  region  = "ap-east-1"
  profile = "genius"
}

variable "STAGE" { type = string }

locals {
  env           = merge(jsondecode(file(".env.prod.json")), { STAGE = var.STAGE })
  function_name = "gofiber_lambda_boilerplate"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "bin/bootstrap"
  output_path = "bin/lambda_function_payload.zip"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy" "iam_for_lambda" {
  name = "iam_for_lambda"
  role = aws_iam_role.iam_for_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_api_gateway_rest_api" "gofiber_lambda_boilerplate_apigateway" {
  name        = "gofiber_lambda_boilerplate_apigw"
  description = "Gofiber Lambda Boilerplate API Gateway"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.gofiber_lambda_boilerplate_apigateway.id
  path_part   = "{proxy+}"
  parent_id   = aws_api_gateway_rest_api.gofiber_lambda_boilerplate_apigateway.root_resource_id
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.gofiber_lambda_boilerplate_apigateway.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.gofiber_lambda_boilerplate_apigateway.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.gofiber_lambda_boilerplate.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.gofiber_lambda_boilerplate_apigateway.id
  resource_id   = aws_api_gateway_rest_api.gofiber_lambda_boilerplate_apigateway.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.gofiber_lambda_boilerplate_apigateway.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.gofiber_lambda_boilerplate.invoke_arn
}

resource "aws_lambda_permission" "execution_lambda_from_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gofiber_lambda_boilerplate.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gofiber_lambda_boilerplate_apigateway.execution_arn}/*/*"
}

resource "aws_lambda_function" "gofiber_lambda_boilerplate" {
  filename         = "bin/lambda_function_payload.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = local.function_name
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2"
  architectures    = ["arm64"]
  depends_on       = [aws_cloudwatch_log_group.lambda_log_group]
  environment {
    variables = local.env
  }
}

resource "aws_api_gateway_deployment" "gofiber_lambda_boilerplate" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.gofiber_lambda_boilerplate_apigateway.id
  stage_name  = local.env.STAGE
}

output "api_endpoint" {
  value = aws_api_gateway_deployment.gofiber_lambda_boilerplate.invoke_url
}
