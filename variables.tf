variable "region" {
  type        = string
  description = "AWS Region where to provision VPC Network"
}

variable "profile" {
  type        = string
  description = "AWS profile name"
}

variable "repo_name" {
  type = string
  # default = "test"
}

variable "image_tag" {
  type = string
  # default = "1.20.2"
}

variable "build_dir" {
  type = string
  # default = "build"
}

variable "dockerfile" {
  type = string
  # default = "Dockerfile"
}

variable "build_args" {
  type = map(string)
  # default = {
  #   VERSION = "latest"
  #   BUILD_VERSION = "1.1.1"
  # }
}

variable "build_labels" {
  type = map(string)
  # default = {
  #   author : "mikayel galyan"
  # }
}
