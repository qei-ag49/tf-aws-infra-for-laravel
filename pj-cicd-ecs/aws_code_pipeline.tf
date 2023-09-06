# GitHubリポジトリの情報
data "github_repository" "laravel_app" {
  name = var.github_repo_full_name
}

# 
# CodePipeline
# 
resource "aws_codepipeline" "laravel_pipeline" {
  name     = "laravel-app-pipeline"
  role_arn = aws_iam_role.laravel_pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.laravel_s3_bucket.bucket # 先に作成されたS3バケットを指定
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name = "SourceAction"
      # name     = "S3SourceAction"
      category = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"
      # provider = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.code_star_connection.arn
        FullRepositoryId     = "${var.github_repo_owner}/${var.github_repo_name}"
        BranchName           = "main"
        OutputArtifactFormat = "CODE_ZIP"
      }
      # configuration = {
      #   S3Bucket = "laravel-s3-bucket-by-tf"
      #   S3ObjectKey = "s3://laravel-s3-bucket/laravel-app.zip"
      # }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.laravel_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.laravel_cluster.name
        ServiceName = aws_ecs_service.laravel_service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}

# IAM role(codestar)
data "aws_iam_policy_document" "codestar_connections_policy" {
  statement {
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection"
    ]
    resources = ["arn:aws:codestar-connections:*:*:connection/*"]
  }
}

resource "aws_iam_role_policy" "codestar_connections_policy_attachment" {
  name   = "codestar-connections-policy-attachment"
  role   = aws_iam_role.laravel_pipeline_role.id
  policy = data.aws_iam_policy_document.codestar_connections_policy.json
}

# IAM role
resource "aws_iam_role" "laravel_pipeline_role" {
  name = "laravel-pipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

# IAM policy
resource "aws_iam_role_policy_attachment" "codebuild_full_access" {
  role       = aws_iam_role.laravel_pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_full_access" {
  role       = aws_iam_role.laravel_pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.laravel_pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "codepipeline_full_access" {
  role       = aws_iam_role.laravel_pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

# 
# CodeBuild
# 
resource "aws_codebuild_project" "laravel_build" {
  name         = "laravel-app-build"
  description  = "Build Laravel application"
  service_role = aws_iam_role.laravel_codebuild_role.arn
  source {
    type      = "GITHUB"
    location  = "https://github.com/qei-ag49/laravel8-video-learning.git"
    buildspec = "buildspec.yml"
  }

  # artifacts {
  #   type = "NO_ARTIFACTS" # アーティファクトを生成しない場合
  # }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"       # ビルドに使用するコンピューティング環境のタイプ
    image           = "aws/codebuild/standard:4.0" # 使用するビルドイメージ
    type            = "LINUX_CONTAINER"            # イメージのタイプ
    privileged_mode = true                         # 特権モードを有効にする
  }
}


# IAM role
resource "aws_iam_role" "laravel_codebuild_role" {
  name = "laravel-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

# IAM policyの定義
resource "aws_iam_policy" "codebuild_cloudwatch_policy" {
  name        = "codebuild-cloudwatch-policy"
  description = "Policy for CodeBuild to access CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:log-group:/aws/codebuild/*"
      }
    ]
  })
}

# IAM policyをIAM roleにアタッチ
resource "aws_iam_role_policy_attachment" "codebuild_admin_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
  role       = aws_iam_role.laravel_codebuild_role.name
}

resource "aws_iam_role_policy_attachment" "codebuild_cloudwatch_attachment" {
  policy_arn = aws_iam_policy.codebuild_cloudwatch_policy.arn
  role       = aws_iam_role.laravel_codebuild_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  policy_arn = aws_iam_policy.ecr_full_access_policy.arn
  role       = aws_iam_role.laravel_codebuild_role.name
}

resource "aws_iam_policy_attachment" "codebuild_s3_access_attachment" {
  name       = "laravel-codebuild-s3-access-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  roles      = [aws_iam_role.laravel_codebuild_role.name]
}

resource "aws_iam_policy_attachment" "ecr_policy_attachment" {
  name       = "ecr-policy-attachment"
  roles      = [aws_iam_role.laravel_codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# IAM policyの定義
resource "aws_iam_policy" "ecr_full_access_policy" {
  name        = "ECRFullAccessPolicy"
  description = "Policy for full access to Amazon ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "ecr:*",
      Resource = "*"
    }]
  })
}
