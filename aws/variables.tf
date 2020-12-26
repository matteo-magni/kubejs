variable "region" {
  description = "The AWS region we want to create the resources into"
  default = "eu-west-1"
}

variable "k8s_cluster" {
  description = "DNS name of the kubernetes cluster"
  default = "mycluster.example.com"
}

variable "k8s_username" {
  description = "Username to authenticate to the kubernetes cluster with"
  default = "codebuild"
}

variable "k8s_password_parameter" {
  description = "Parameter name in SSM Parameter Store holding the kubernetes password"
  default = "/codebuild/k8s/password"
}
