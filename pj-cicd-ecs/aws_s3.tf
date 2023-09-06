resource "aws_s3_bucket" "laravel_s3_bucket" {
  bucket = "laravel-s3-bucket-by-tf"
}

resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
  bucket = aws_s3_bucket.laravel_s3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket = aws_s3_bucket.laravel_s3_bucket.id

  block_public_acls = false
}
