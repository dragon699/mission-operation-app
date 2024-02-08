data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "satellite_app" {
    name = "satellite_app"
  
    image_scanning_configuration {
      scan_on_push = false
    }

    tags = {
      Service     = "satellite_app"
      Description = "Satellites application ECR repository to hold the application Docker image."
    }
}


resource "null_resource" "satellite_app_docker_build" {
	provisioner "local-exec" {
	  command = templatefile(
        "../scripts/build_and_push.sh.tftpl", {
          region     = var.region,
          account_id = data.aws_caller_identity.current.account_id,
          image_tag  = "${aws_ecr_repository.satellite_app.repository_url}:latest"
        }
      )
	}

	triggers = {
	  "run_at" = timestamp()
	}

	depends_on = [
      aws_db_instance.satellite_app,
	  aws_ecr_repository.satellite_app
	]
}

# resource "aws_apprunner_vpc_connector" "satellite_app" {
#     vpc_connector_name = "satellite-app-apprunner-rds"

#     subnets = aws_subnet.satellite_app_database[*].id
#     security_groups = [aws_security_group.satellite_app_database.id]

#     tags = {
#       Service     = "satellite_app"
#       Description = "Satellites application AppRunner to RDS Database VPC connector - will make the connection possible."
#     }
# }

resource "aws_apprunner_service" "satellite_app" {
    service_name = "satellite-app"
  
    source_configuration {
      auto_deployments_enabled             = true

      image_repository {
        image_configuration {
          port                             = var.app_port
          runtime_environment_variables = {
            DATABASE_NAME                  = var.db_name
            DATABASE_USER                  = var.db_username
            DATABASE_PASSWORD              = var.db_password
            DATABASE_HOST                  = aws_db_instance.satellite_app.address
            DATABASE_PORT                  = var.db_port
            APP_PORT                       = var.app_port
            S3_BUCKET_NAME                 = var.app_bucket_name
            S3_BUCKET_SATELLITES_FILE_NAME = var.app_bucket_file_key
          }
        }
  
        image_identifier                   = "${aws_ecr_repository.satellite_app.repository_url}:latest"
        image_repository_type              = "ECR"
      }

      authentication_configuration {
        access_role_arn                    = aws_iam_role.satellite_app_ecr.arn
      }
    }
  
    instance_configuration {
      cpu                                  = "1024"
      memory                               = "2048"
      instance_role_arn                    = aws_iam_role.satellite_app_apprunner.arn
    }

    network_configuration {
      ingress_configuration {
        is_publicly_accessible             = true
      }

      egress_configuration {
        egress_type                        = "DEFAULT"
        # vpc_connector_arn                  = aws_apprunner_vpc_connector.satellite_app.arn
      }
    }

    depends_on = [
      aws_iam_role.satellite_app_ecr,
      aws_iam_role_policy_attachment.satellite_app_apprunner,
      null_resource.satellite_app_docker_build,
    #   aws_vpc_endpoint.satellite_app_s3,
    #   aws_vpc_endpoint.satellite_app_rds
    ]
  
    tags = {
      Service                              = "satellite_app"
      Description                          = "Satellites Backend API application runner service"
    }
}
