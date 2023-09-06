#!/usr/bin/env bash

# 
# プロジェクトディレクトリから、`sh ../doProcess2.sh`を実行させるイメージ
# 

# バージョニング管理されたS3リソースを削除
aws s3api delete-objects --bucket laravel-s3-bucket-by-tf --delete "$(aws s3api list-object-versions --bucket laravel-s3-bucket-by-tf | jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"
aws ecr delete-repository --repository-name laravel-app-repo --force

# AWSリソースを全て削除
terraform destroy -auto-approve
