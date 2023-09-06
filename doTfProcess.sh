#!/usr/bin/env bash

# 
# プロジェクトディレクトリから、`sh ../doProcess.sh`を実行させるイメージ
# 

# Terraformの実行に必要なプラグインを取得
terraform init

# Terraformコードの構文に問題がないことを確認
terraform validate

# コードのインデントを自動で整形
terraform fmt

terraform plan

# codestar接続だけ先に作成する
# aws codestar-connections create-connection \
#   --provider-type GitHub \
#   --name larevel_cicd_connection_by_tf \
#   --tags Name=codeStarConnectionByTf,Environment=sandbox,Source=terraform,Project=pjCicdEcs

# AWS環境に適用
terraform apply -auto-approve

# リソースを削除
# terraform destroy
