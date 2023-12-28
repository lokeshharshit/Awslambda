provider "aws" {
  region     = "ap-south-1"  # Change this to your desired AWS region
  access_key = "AKIAXCZ7OEEQR4AAN5HT"
  secret_key = "4LguD9blM4PCme165i2BJ+Jld9Xlu1BnfIVIv5NE"
}

resource "aws_lambda_function" "my_lambda_function" {
  function_name    = "my-lambda-function"
  runtime          = "python3.10"
  handler          = "lambda_function.lambda_handler"
  filename         = "lambda_function/lambda_function.zip"
  role             = aws_iam_role.lambda_execution_role.arn
  source_code_hash = filebase64sha256("lambda_function/lambda_function.zip")
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_api_gateway_rest_api" "my_api" {
  name        = "my-api"
  description = "My API"
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "my-resource"
}

# Define GET method
resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Define GET integration
resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.get_method.http_method

  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda_function.invoke_arn
}

# Define POST method
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Define POST integration
resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.post_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda_function.invoke_arn
}

# Define PUT method
resource "aws_api_gateway_method" "put_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

# Define PUT integration
resource "aws_api_gateway_integration" "put_integration" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.put_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda_function.invoke_arn
}

# Define DELETE method
resource "aws_api_gateway_method" "delete_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
}

# Define DELETE integration
resource "aws_api_gateway_integration" "delete_integration" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.delete_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda_function.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.get_integration,
    aws_api_gateway_integration.post_integration,
    aws_api_gateway_integration.put_integration,
    aws_api_gateway_integration.delete_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = "prod"
}

resource "aws_api_gateway_model" "my_model" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  name        = "MyModel"
  description = "My Model Description"
  content_type = "application/json"

  schema = <<EOF
{
  "type": "object",
  "properties": {
    "id": {"type": "string"},
    "title": {"type": "string"},
    "description": {"type": "string"},
    "completed": {"type": "boolean"}
  }
}
EOF
}
