# Provided in separate secrets file, or at runtime
variable "packet_auth_token" {}
variable "packet_project_id" {}

provider "packet" {
  auth_token = "${var.packet_auth_token}"
}

locals {
  project_id = "${var.packet_project_id}"
}

# Baby server for running our kubernetes master. Small, but very important :)
# resource "packet_device" "lily" {
#   hostname         = "lily"
#   plan             = "t1.small.x86"
#   facilities = ["sjc1"]
#   operating_system = "centos_7"
#   billing_cycle    = "hourly"
#   project_id       = "${var.packet_project_id}"
#   tags = ["antidote-master"]
#   depends_on       = ["packet_ssh_key.mierdinkey"]
# }

# resource "packet_device" "antidote-worker" {
#   count = 3
#   hostname         = "antidote-worker-${count.index}"
#   plan             = "c1.small.x86"
#   facilities = ["sjc1"]
#   operating_system = "centos_7"
#   billing_cycle    = "hourly"
#   project_id       = "${var.packet_project_id}"
#   tags = ["antidote-worker"]
#   depends_on       = ["packet_ssh_key.mierdinkey"]
# }

resource "packet_ssh_key" "mierdinkey" {
  name       = "mierdinkey"
  public_key = "${file("/home/mierdin/.ssh/id_rsa.pub")}"
}
