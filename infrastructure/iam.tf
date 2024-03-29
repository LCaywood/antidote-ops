
###############
# Ansible     #
###############

resource "google_service_account" "ansiblesa" {
  account_id   = "ansiblesa"
  display_name = "ansiblesa"
  project      = "${var.project}"
}

resource "google_service_account_key" "ansible-key" {
  service_account_id = "${google_service_account.ansiblesa.name}"
}

resource "local_file" "ansible-key-file" {
  content  = "${base64decode(google_service_account_key.ansible-key.private_key)}"
  filename = "${path.module}/inventory/ansiblekey.json"
}

resource "google_project_iam_binding" "ansible-bind" {
  project = "${var.project}"
  role = "roles/compute.viewer"

  members = [
    "serviceAccount:ansiblesa@${var.project_name}.iam.gserviceaccount.com",
  ]
}


###############
# Storage     #
###############

# Used primarily for retrieving base images like qcow or img files.

resource "google_service_account" "storagesa" {
  account_id   = "storagesa"
  display_name = "storagesa"
  project      = "${var.project}"
}

resource "google_service_account_key" "storagesa-key" {
  service_account_id = "${google_service_account.storagesa.name}"
}

resource "local_file" "storagesa-key-file" {
  content  = "${base64decode(google_service_account_key.storagesa-key.private_key)}"
  filename = "${path.module}/inventory/storagesakey.json"
}

resource "google_project_iam_binding" "storagesa-bind" {
  project = "${var.project}"
  role = "roles/storage.objectViewer"

  members = [
    "serviceAccount:storagesa@${var.project_name}.iam.gserviceaccount.com",
  ]
}


###############
# Stackdriver #
###############

# resource "google_service_account" "stackdriversa" {
#   account_id   = "stackdriversa"
#   display_name = "stackdriversa"
#   project      = "${var.project}"
# }
# resource "google_project_iam_binding" "stackdriversa-bind-metrics" {
#   project = "${var.project}"
#   role    = "roles/monitoring.metricWriter"

#   members = [
#     "serviceAccount:stackdriversa@${var.project_name}.iam.gserviceaccount.com",
#   ]
# }

# resource "google_project_iam_binding" "stackdriversa-bind-logs" {
#   project = "${var.project}"
#   role    = "roles/logging.logWriter"

#   members = [
#     "serviceAccount:stackdriversa@${var.project_name}.iam.gserviceaccount.com",
#   ]
# }

# resource "google_service_account_key" "stackdriversa-key" {
#   service_account_id = "${google_service_account.stackdriversa.name}"
# }

# resource "local_file" "stackdriversa-key-file" {
#   content  = "${base64decode(google_service_account_key.stackdriversa-key.private_key)}"
#   filename = "${path.module}/tmp/stackdriversakey.json"
# }
