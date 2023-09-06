resource "aws_ssm_parameter" "psql_database" {
  name        = "/laravel/psql_database"
  description = "PostgreSQL Database Name"
  type        = "String"
  value       = "video_learning"
}

resource "aws_ssm_parameter" "psql_user" {
  name        = "/laravel/psql_user"
  description = "PostgreSQL User Name"
  type        = "String"
  value       = "sample_user"
}

resource "aws_ssm_parameter" "psql_password" {
  name        = "/laravel/psql_password"
  description = "PostgreSQL Password"
  type        = "SecureString"
  value       = ""
}

resource "aws_ssm_parameter" "psql_root_password" {
  name        = "/laravel/psql_root_password"
  description = "PostgreSQL Root Password"
  type        = "SecureString"
  value       = ""
}

# RDSを利用する場合は、RDSのエンドポイントを指定する
resource "aws_ssm_parameter" "psql_db_endpoint" {
  name        = "/laravel/psql_db_endpoint"
  description = "PostgreSQL"
  type        = "String"
  value       = "dummy"
}
