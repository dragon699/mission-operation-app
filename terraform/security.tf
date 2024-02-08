resource "aws_security_group" "satellite_app_database" {
    name          = "satellite_app_postgresql"
    description   = "Satellite application (RDS) database security group"
    vpc_id        = aws_vpc.satellite_app.id

    ingress {
      protocol    = "tcp"
      from_port   = var.db_port
      to_port     = var.db_port
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Service     = "satellite_app"
      Description = "Satellites application (RDS) database security group"
    }
}

resource "aws_iam_role" "satellite_app_ecr" {
    name = "satellite_app_ecr"

    assume_role_policy = file(
      "assets/policies/iam_ecr_trusted_entities.json"
    )

    inline_policy {
      name = "satellite_app_ecr"

      policy = file(
        "assets/policies/iam_ecr_policy.json"
      )
    }

    tags = {
      Service     = "satellite_app"
      Description = "Satellites application IAM role and policy for ECR"
    }
}

resource "aws_iam_role" "satellite_app_apprunner" {
    name               = "satellite_app_apprunner"

    assume_role_policy = file(
      "assets/policies/iam_apprunner_trusted_entities.json"
    )

    tags = {
      Service     = "satellite_app"
      Description = "Satellites application IAM role"
    }
}

resource "aws_iam_policy" "satellite_app_apprunner" {
    name        = "satellite_app_apprunner"
    description = "Satellite Backend API application IAM policy"

    policy      = templatefile(
      "assets/policies/iam_apprunner_policy.json.tftpl", {
        app_bucket_name = var.app_bucket_name
      }
    )

    tags = {
      Service     = "satellite_app"
      Description = "Satellites application IAM policy"
    }
}

resource "aws_iam_role_policy_attachment" "satellite_app_apprunner" {
    role       = aws_iam_role.satellite_app_apprunner.name
    policy_arn = aws_iam_policy.satellite_app_apprunner.arn
}
