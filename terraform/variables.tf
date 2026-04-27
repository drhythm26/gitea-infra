variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "asia-east2"
}

variable "zone" {
  type    = string
  default = "asia-east2-a"
}

variable "vpc_name" {
  type    = string
  default = "gitea-vpc"
}

variable "image_family" {
  type    = string
  default = "ubuntu-2404-lts-amd64"
}

variable "image_project" {
  type    = string
  default = "ubuntu-os-cloud"
}

variable "ssh_user" {
  type    = string
  default = "lan"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/google_compute_engine.pub"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "admin_cidr" {
  type = list(string)
} 