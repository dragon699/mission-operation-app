variable "region" {
    type        = string
    description = "The AWS region to deploy mission operations app to"
}

variable "db_cidrs" {
    type        = list(string)
    description = "List of CIDR blocks to use for the database subnets"
    default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "db_username" {
    type        = string
    description = "The username to use for the database"
}

variable "db_password" {
    type        = string
    description = "The password to use for the database"
}

variable "db_name" {
    type        = string
    description = "The name of the database to create"
}

variable "db_port" {
    type        = number
    description = "The port the database will listen on"
}

variable "app_port" {
    type        = number
    description = "The port the Backend API application will listen on"
}

variable "app_bucket_name" {
    type        = string
    description = "The name of the S3 bucket to use for the application"
}

variable "app_bucket_file_key" {
    type        = string
    description = "The file name to upload application telemetry data to"
}
