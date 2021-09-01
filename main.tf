provider "aws" {
  region  = var.region
  profile = var.profile
}
terraform {
  backend "s3" {
    bucket  = "mikayel"                                // Bucket where to SAVE Terraform State
    key     = "terraform/test_ecr/terraform.tfstate.*" // Object name in the bucket to SAVE Terraform State
    region  = "us-east-1"                              // Region where bucket is created
    encrypt = true
  }
}
data "aws_ecr_authorization_token" "ecr_token" {}

data "aws_caller_identity" "current" {}

data "aws_ecr_repository" "exist" {
  name       = var.repo_name
  depends_on = [null_resource.ecr_repo_create]
}

resource "null_resource" "renew_ecr_token" {
  triggers = {
    token_expired = data.aws_ecr_authorization_token.ecr_token.expires_at
  }
  provisioner "local-exec" {
    command     = "aws ecr get-login-password --region ${var.region} | docker login  --username AWS  --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.${var.region}.amazonaws.com; sleep 10"
    interpreter = ["bash", "-c"]
  }
}

resource "null_resource" "ecr_repo_create" {
  triggers = {
    name_changed = var.repo_name
  }
  provisioner "local-exec" {
    command     = "aws ecr describe-repositories --repository-names ${var.repo_name} --profile ${var.profile} --region ${var.region}|| aws ecr create-repository --repository-name ${var.repo_name}  --profile ${var.profile} --region ${var.region}"
    interpreter = ["bash", "-c"]
  }
}

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
  }
}

provider "docker" {
  host = "tcp://localhost:2375"
  registry_auth {
    address     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
    config_file = pathexpand("~/.docker/config.json")
  }
}

resource "docker_registry_image" "image" {
  name = "${data.aws_ecr_repository.exist.repository_url}:${var.image_tag}"
  build {
    # context = "D:\\terraform\\test_ecr\\build\\"
    context    = "${replace(path.cwd, "/", "\\")}\\${var.build_dir}\\"
    dockerfile = "Dockerfile"
    build_args = var.build_args
    remove     = true
    labels     = var.build_labels
  }
  # lifecycle {
  #   prevent_destroy = true
  #   ignore_changes  = [name, ]
  # }
  depends_on = [null_resource.renew_ecr_token]
}

# resource "docker_image" "nginx_brotli_image" {
#   name = "nginx-brotli:map"
#   build {
#     path = "./build"
#     # tag  = ["zoo:develop"]
#     build_arg = {
#       VERSION : "16.8.0-alpine3.14"
#     }
#     label = {
#       author : "Mikayel Galyan"
#     }
#   }
# }

output "image" {
  value = docker_registry_image.image.name
}
