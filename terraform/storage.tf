resource "aws_s3_bucket" "satellite_app" {
    bucket = var.app_bucket_name

    tags = {
      Service     = "satellite_app"
      Description = "Satellites application S3 bucket. Will be used to store the satellites telemetry data."
    }
}

resource "aws_s3_object" "satellite_app_telemetry_data" {
    bucket = aws_s3_bucket.satellite_app.id
    key    = var.app_bucket_file_key
    source = "assets/${var.app_bucket_file_key}"
}

resource "aws_db_instance" "satellite_app" {
    identifier                          = "satellite-app"

    instance_class                      = "db.t3.micro"
    storage_type                        = "gp2"
    allocated_storage                   = 20

    engine                              = "postgres"
    engine_version                      = "15.5"
    db_name                             = var.db_name
    username                            = var.db_username
    password                            = var.db_password

    auto_minor_version_upgrade          = false
    enabled_cloudwatch_logs_exports     = ["postgresql"]

    apply_immediately                   = true

    publicly_accessible                 = true
    iam_database_authentication_enabled = true
    skip_final_snapshot                 = true

    vpc_security_group_ids              = [aws_security_group.satellite_app_database.id]
    db_subnet_group_name                = aws_db_subnet_group.satellite_app.id
}
