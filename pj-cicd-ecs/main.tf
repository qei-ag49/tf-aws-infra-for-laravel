provider "aws" {
  region = "ap-northeast-1"
}

# terraform {
#   required_providers {
#     aws = {
#       source = "hashicorp/aws"
#       version = "~> 4.54.0"
#     }
#   }
# }

resource "aws_codestarconnections_connection" "code_star_connection" {
  provider_type = "GitHub"
  name          = "larevel_cicd_connection_by_tf"

  tags = {
    Name        = "codeStarConnectionByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}
