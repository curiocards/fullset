# Define the AWS Lambda function
resource "aws_lambda_function" "generate_fullset" {
  filename         = "lambda/lambda_function.zip"
  function_name    = "generate_fullset"
  role             = aws_iam_role.curio_fullset_lambda_execution_role.arn
  runtime          = "python3.9"
  handler          = "lambda_function.lambda_handler"
  timeout          = 30

  environment {
    variables = {
      NFTGO_API_KEY = var.NFTGO_API_KEY
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_event_rule" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_fullset.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.curio_fullset_cronjob.arn
}

# Create a CloudWatch event rule that triggers every 15 minutes
resource "aws_cloudwatch_event_rule" "curio_fullset_cronjob" {
  name        = "curio_fullset_cronjob"
  schedule_expression    = "rate(15 minutes)"
  role_arn = aws_iam_role.curio_fullset_lambda_execution_role.arn
}

# Create a CloudWatch event target that points to the Lambda function
resource "aws_cloudwatch_event_target" "generate_fullset" {
  rule      = aws_cloudwatch_event_rule.curio_fullset_cronjob.name
  target_id = "generate_fullset"
  arn       = aws_lambda_function.generate_fullset.arn
}

# Define the IAM role that the Lambda function will use
resource "aws_iam_role" "curio_fullset_lambda_execution_role" {
  name = "curio_fullset_lambda_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "events.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the necessary permissions to the IAM role
resource "aws_iam_role_policy" "curio_fullset_lambda_execution_policy" {
  name = "curio_fullset_lambda_execution_policy"
  role = "${aws_iam_role.curio_fullset_lambda_execution_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::fullset.curio.cards/*"
    }
  ]
}
EOF
}

# Define the S3 bucket
resource "aws_s3_bucket" "fullset_curio_cards" {
  bucket = "fullset.curio.cards"
  acl = "public-read"
}

resource "aws_s3_bucket_website_configuration" "fullset_curio_cards" {
  bucket = aws_s3_bucket.fullset_curio_cards.id

  index_document {
    suffix = "index.html"
  }
}
