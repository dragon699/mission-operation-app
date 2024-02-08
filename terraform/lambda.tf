data "aws_iam_policy_document" "satellite_app_lambda" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "satellite_app_lambda" {
  name               = "satellite_app_lambda"
  assume_role_policy = data.aws_iam_policy_document.satellite_app_lambda.json
}

data "archive_file" "satellite_app_lambda" {
  type        = "zip"
  source_file  = "../scripts/lambda.py"
  output_path = "../scripts/satellite-app-lambda.zip"
}

resource "aws_lambda_function" "satellite_app_lambda" {
  runtime          = "python3.12"

  filename         = data.archive_file.satellite_app_lambda.output_path
  function_name    = "satellite_app_lambda"
  role             = aws_iam_role.satellite_app_lambda.arn
  handler          = "lambda.lambda_handler"

  source_code_hash = data.archive_file.satellite_app_lambda.output_base64sha256

  environment {
    variables = {
      APP_URL = "https://${aws_apprunner_service.satellite_app.service_url}"
    }
  }

  tags = {
    Service = "satellite_app"
    Description = "Lambda function for telemetry processing of satellite application data"
  }
}
