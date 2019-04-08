
# Provided at runtime
variable "billing_account" {}

provider "google" {
  region  = "${var.region}"
  version = "~> 1.17.1"
}

resource "random_id" "id" {
  byte_length = 4
  prefix      = "${var.project_name}-"
}

resource "google_project" "project" {
  name = "${var.project_name}"

  project_id      = "${random_id.id.hex}"
  billing_account = "${var.billing_account}"
}

resource "google_project_services" "project" {
  project = "${var.project}"

  disable_on_destroy = false

  services = [
    "compute.googleapis.com",
    "oslogin.googleapis.com",
    "iam.googleapis.com",
    "dns.googleapis.com",
  ]
}
