data "google_compute_region_instance_group" "controllers" {
  project   = "${var.project}"
  region    = "${var.region}"
  self_link = "${google_compute_region_instance_group_manager.controllers.instance_group}"
}

data "google_compute_instance_group" "controller-ha-group-0" {
  project   = "${var.project}"
  self_link = "${google_compute_instance_group.controller-ha-group-0.self_link}"
}

data "google_compute_instance_group" "controller-ha-group-1" {
  project   = "${var.project}"
  self_link = "${google_compute_instance_group.controller-ha-group-1.self_link}"
}


data "google_compute_instance_group" "controller-ha-group-2" {
  project   = "${var.project}"
  self_link = "${google_compute_instance_group.controller-ha-group-2.self_link}"
}


data "google_compute_region_instance_group" "workers" {
  project   = "${var.project}"
  region    = "${var.region}"
  self_link = "${google_compute_region_instance_group_manager.workers.instance_group}"
}

resource "google_compute_region_instance_group_manager" "controllers" {
  name    = "controllers"
  project = "${var.project}"

  base_instance_name = "antidote-controller"
  instance_template  = "${google_compute_instance_template.controllers.self_link}"
  region             = "${var.region}"

  named_port {
    name = "k8sapi"
    port = 6443
  }
}

resource "google_compute_region_instance_group_manager" "workers" {
  name    = "workers"
  project = "${var.project}"

  base_instance_name = "antidote-worker"
  instance_template  = "${google_compute_instance_template.workers.self_link}"
  region             = "${var.region}"

  named_port {
    name = "nrehttp"
    port = 30001
  }

  named_port {
    name = "nrehttps"
    port = 30002
  }
}

resource "google_compute_region_autoscaler" "controllers-scaler" {
  name    = "controllers-scaler"
  project = "${var.project}"
  region  = "${var.region}"
  target  = "${google_compute_region_instance_group_manager.controllers.self_link}"

  autoscaling_policy = {
    max_replicas    = 1
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.8
    }
  }
}

resource "google_compute_region_autoscaler" "workers-scaler" {
  name    = "workers-scaler"
  project = "${var.project}"
  region  = "${var.region}"
  target  = "${google_compute_region_instance_group_manager.workers.self_link}"

  autoscaling_policy = {
    max_replicas    = 3
    min_replicas    = 3
    cooldown_period = 60

    cpu_utilization {
      target = 0.8
    }
  }
}

resource "google_compute_instance_template" "controllers" {
  name        = "controllers"
  project     = "${var.project}"
  description = "This template is used to create antidote controller instances."

  tags         = ["antidote", "kubernetes", "kubernetescontrollers"]
  machine_type = "n1-standard-2"

  depends_on = [
    # "google_project_services.project",
    "google_compute_image.nested-vm-image",
  ]

  instance_description = "antidote controller instance"
  can_ip_forward       = true

  # scheduling {
  #   automatic_restart   = true
  #   on_host_maintenance = "MIGRATE"
  # }

  disk {
    source_image = "${google_compute_image.nested-vm-image.name}"
    auto_delete  = true
    boot         = true
    # disk_type = "pd-ssd"
  }
  network_interface {
    network       = "${google_compute_network.default-internal.name}"
    access_config = {}
  }
}

resource "google_compute_instance_group" "controller-ha-group-0" {
  name        = "controller-ha-group-0"
  description = "Unmanaged instance group for controllers-ha-0"
  zone        = "${var.zone1}"
  network     = "${google_compute_network.default-internal.self_link}"
  instances = [
    "${google_compute_instance_from_template.controllers-ha-0.self_link}",
  ]
}

resource "google_compute_instance_from_template" "controllers-ha-0" {
  name = "controllers-ha-0"
  zone           = "${var.zone1}"
  source_instance_template = "${google_compute_instance_template.controllers-ha.self_link}"
}


resource "google_compute_instance_group" "controller-ha-group-1" {
  name        = "controller-ha-group-1"
  description = "Unmanaged instance group for controllers-ha-1"
  zone        = "${var.zone2}"
  network     = "${google_compute_network.default-internal.self_link}"
  # instances = [
  #   "${google_compute_instance_from_template.controllers-ha-1.self_link}",
  # ]
}

resource "google_compute_instance_from_template" "controllers-ha-1" {
  name = "controllers-ha-1"
  zone           = "${var.zone2}"
  source_instance_template = "${google_compute_instance_template.controllers-ha.self_link}"
}


resource "google_compute_instance_group" "controller-ha-group-2" {
  name        = "controller-ha-group-2"
  description = "Unmanaged instance group for controllers-ha-2"
  zone        = "${var.zone3}"
  network     = "${google_compute_network.default-internal.self_link}"
  # instances = [
  #   "${google_compute_instance_from_template.controllers-ha-2.self_link}",
  # ]
}

resource "google_compute_instance_from_template" "controllers-ha-2" {
  name = "controllers-ha-2"
  zone           = "${var.zone3}"
  source_instance_template = "${google_compute_instance_template.controllers-ha.self_link}"
}

resource "google_compute_instance_template" "controllers-ha" {
  name        = "controllers-ha"
  project     = "${var.project}"
  description = "This template is used to create antidote controller instances."

  tags         = ["antidote", "kubernetes", "kubernetescontrollers", "k8s-ha"]
  # machine_type = "n1-standard-1"
  machine_type = "custom-2-4096"

  instance_description = "antidote controller instance"
  can_ip_forward       = true

  # scheduling {
  #   automatic_restart   = true
  #   on_host_maintenance = "MIGRATE"
  # }

  disk {
    # source_image = "${google_compute_image.nested-vm-image.name}"
    source_image = "${var.os["centos-7-2019"]}"
    auto_delete  = true
    boot         = true
    # disk_type = "pd-ssd"
  }
  network_interface {
    network       = "${google_compute_network.default-internal.name}"
    access_config = {}
  }
}


resource "google_compute_instance_template" "workers" {
  name        = "workers"
  project     = "${var.project}"
  description = "This template is used to create antidote workers instances."

  tags = ["antidote", "kubernetes", "kubernetesworkers"]

  # 8 vCPUs, 30GB RAM
  machine_type = "n1-standard-16"

  depends_on = [
    # "google_project_services.project",
    "google_compute_image.nested-vm-image",
  ]

  instance_description = "antidote workers instance"
  can_ip_forward       = true

  # scheduling {
  #   automatic_restart   = true
  #   on_host_maintenance = "MIGRATE"
  # }

  disk {
    source_image = "${google_compute_image.nested-vm-image.name}"
    auto_delete  = true
    boot         = true
    # disk_type = "pd-ssd"
  }
  network_interface {
    network       = "${google_compute_network.default-internal.name}"
    access_config = {}
  }
}


resource "google_compute_instance" "abathur" {
  name        = "abathur"
  zone        = "${var.zone}"
  project     = "${var.project}"
  description = "Antidote automation server"

  tags = ["st2"]

  # 2 vCPUs, 7.5GB RAM
  machine_type = "n1-standard-4"

  boot_disk {
    initialize_params {
    image = "${var.os["centos-7"]}"
    }
  }

  network_interface {
    network       = "${google_compute_network.default-internal.name}"
    access_config = {}
  }
}
