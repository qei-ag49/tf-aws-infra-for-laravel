# ACM証明書
resource "aws_acm_certificate" "laravel_certificate" {
  domain_name       = "kemmy.tokyo"
  validation_method = "DNS"

  tags = {
    Name        = "acmByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}
