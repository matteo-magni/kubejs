provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_ecr_repository" "nginx" {
  name                 = "nginx-proxy"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "nodejs" {
  name                 = "nodejs-react"
  image_tag_mutability = "MUTABLE"
}

data "aws_ssm_parameter" "k8s_password" {
  name = var.k8s_password_parameter
  with_decryption = false
}

resource "aws_iam_role" "role" {
  name = "kubejs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "role_resource_policy_doc" {

  statement {
    resources = [
      "*"
    ]
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }
  
  statement {
    resources = [
      "*"
    ]

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
  }

  statement {
    resources = [
      data.aws_ssm_parameter.k8s_password.arn
    ]
    
    actions = [
        "ssm:GetParameters"
    ]
  }
  
}
resource "aws_iam_role_policy" "policy" {
  role = aws_iam_role.role.name
  policy = data.aws_iam_policy_document.role_resource_policy_doc.json
}

resource "aws_codebuild_project" "project" {
  name            = "kubejs"
  description     = "CodeBuild kubejs project"
  build_timeout   = "5"
  service_role    = aws_iam_role.role.arn
  badge_enabled   = true
  source_version  = "master"

  source {
    type                  = "GITHUB"
    location              = "https://github.com/matteo-magni/kubejs.git"
    report_build_status   = true

    git_submodules_config {
      fetch_submodules = true
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                  = "BUILD_GENERAL1_SMALL"
    image                         = "aws/codebuild/standard:4.0"
    type                          = "LINUX_CONTAINER"
    image_pull_credentials_type   = "CODEBUILD"
    privileged_mode               = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "NGINX_REPO_NAME"
      value = aws_ecr_repository.nginx.name
    }

    environment_variable {
      name  = "NODEJS_REPO_NAME"
      value = aws_ecr_repository.nodejs.name
    }

    environment_variable {
      name = "REGISTRY_SECRET_NAME"
      value = "ecr_creds"
    }

    environment_variable {
      name = "K8S_CLUSTER"
      value = var.k8s_cluster
    }

    environment_variable {
      name = "K8S_USERNAME"
      value = var.k8s_username
    }

    environment_variable {
      name = "K8S_PASSWORD"
      value = var.k8s_password_parameter
      type  = "PARAMETER_STORE"
    }

  }

}
