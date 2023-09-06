# お名前.comの反映の確認のため、下記を実行する
# nslookup -type=NS kemmy.tokyo

# Route53のゾーン作成（既存のゾーンがある場合は不要）
resource "aws_route53_zone" "laravel_zone" {
  name = "kemmy.tokyo"

  tags = {
    Name        = "route53ByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

# Aレコードを作成してALBに向ける
resource "aws_route53_record" "laravel_alb_record" {
  zone_id = aws_route53_zone.laravel_zone.zone_id
  name    = "kemmy.tokyo" # もしかしたらここは不要かも。`kemmy.tokyo.kemmy.tokyo`になる可能性がある。
  type    = "A"
  ttl     = "300"

  alias {
    # ALB側で`dns_name`が指定されていなければ、ALBのデフォルトDNS名が提供される
    name                   = aws_lb.laravel_alb.dns_name
    zone_id                = aws_lb.laravel_alb.zone_id
    evaluate_target_health = true
  }

  records = [aws_lb.laravel_alb.dns_name]
}

# 上記のコードは以下の処理を行う
# aws_route53_zoneリソースを使用して、Route53ゾーンを作成します。既にドメインが存在する場合は、この部分は不要
# aws_route53_recordリソースを使用して、Aレコードを作成し、ALBに向けます。aliasブロックを使用して、ALBのDNS名を指定する
# aws_route53_recordリソースを使用して、ACM証明書の確認用レコードを作成します。これにより、ACM証明書の検証が行う

# ACM証明書の検証
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.laravel_certificate.arn
  validation_record_fqdns = [for r in aws_route53_record.laravel_acm_validation_record : r.fqdn]
}

# ACM証明書の検証レコード
resource "aws_route53_record" "laravel_acm_validation_record" {
  count = length(aws_acm_certificate.laravel_certificate.domain_validation_options)

  zone_id = aws_route53_zone.laravel_zone.zone_id
  name    = element(aws_acm_certificate.laravel_certificate.domain_validation_options.*.resource_record_name, count.index)
  type    = element(aws_acm_certificate.laravel_certificate.domain_validation_options.*.resource_record_type, count.index)
  records = [element(aws_acm_certificate.laravel_certificate.domain_validation_options.*.resource_record_value, count.index)]
  ttl     = "300"
}
