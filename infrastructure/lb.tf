resource "google_compute_global_address" "nrefrontend" {
  name    = "nrefrontend"
  project = "${var.project}"
}

resource "google_compute_global_forwarding_rule" "nrehttps" {
  name       = "nrehttps"
  project    = "${var.project}"
  ip_address = "${google_compute_global_address.nrefrontend.address}"
  target     = "${google_compute_target_https_proxy.nrehttpsproxy.self_link}"
  port_range = "443"
}

resource "google_compute_global_forwarding_rule" "nrehttp" {
  name       = "nrehttp"
  project    = "${var.project}"
  ip_address = "${google_compute_global_address.nrefrontend.address}"
  target     = "${google_compute_target_http_proxy.nrehttpproxy.self_link}"
  port_range = "80"
}


resource "google_compute_target_https_proxy" "nrehttpsproxy" {
  name             = "nrehttpsproxy"
  project          = "${var.project}"
  ssl_certificates = ["${var.sslcert}"]
  url_map          = "${google_compute_url_map.https-url-map.self_link}"
}

resource "google_compute_target_http_proxy" "nrehttpproxy" {
  name             = "nrehttpproxy"
  project          = "${var.project}"
  url_map          = "${google_compute_url_map.http-url-map.self_link}"
}

resource "google_compute_url_map" "https-url-map" {
  name    = "https-url-map"
  project = "${var.project}"
  host_rule {
    hosts        = [
      "labs.networkreliability.engineering",
      "ptr.labs.networkreliability.engineering"
    ]

    path_matcher = "${var.prodstate}"
  }

  host_rule {
    hosts        = [
      "maintbypass.labs.networkreliability.engineering"
    ]
    path_matcher = "production"
  }

  # Terraform throws an error if we don't use all path_matchers, so let's use
  # this dummy domain to reference the maintenance path_matcher when it's not being used.
  host_rule {
    hosts        = [
      "maint.labs.networkreliability.engineering"
    ]
    path_matcher = "maintenance"
  }

  host_rule {
    hosts        = [
      "influxdb.networkreliability.engineering"
    ]
    path_matcher = "influxdb"
  }

  host_rule {
    hosts        = [
      "grafana.networkreliability.engineering"
    ]
    path_matcher = "grafana"
  }


  path_matcher {
    name            = "influxdb"
    default_service = "${google_compute_backend_service.observer-influxdb.self_link}"
  }

  path_matcher {
    name            = "production"
    default_service = "${google_compute_backend_service.httpsbackend.self_link}"
  }

  path_matcher {
    name            = "grafana"
    default_service = "${google_compute_backend_service.observer-grafana.self_link}"
  }

  path_matcher {
    name            = "maintenance"
    default_service = "${google_compute_backend_bucket.maintenance.self_link}"
  }

  default_service = "${google_compute_backend_service.httpsbackend.self_link}"
}

resource "google_compute_url_map" "http-url-map" {
  name    = "http-url-map"
  project = "${var.project}"

  host_rule {
    hosts        = [
      "labs.networkreliability.engineering",
      "ptr.labs.networkreliability.engineering"
    ]

    path_matcher = "${var.prodstate}"
  }

  host_rule {
    hosts        = [
      "maintbypass.labs.networkreliability.engineering"
    ]
    path_matcher = "production"
  }


  # Terraform throws an error if we don't use all path_matchers, so let's use
  # this dummy domain to reference the maintenance path_matcher when it's not being used.
  host_rule {
    hosts        = [
      "maint.labs.networkreliability.engineering"
    ]
    path_matcher = "maintenance"
  }

  path_matcher {
    name            = "production"
    default_service = "${google_compute_backend_service.httpbackend.self_link}"
  }

  path_matcher {
    name            = "maintenance"
    default_service = "${google_compute_backend_bucket.maintenance.self_link}"
  }

  default_service = "${google_compute_backend_service.httpbackend.self_link}"
}


resource "google_compute_backend_service" "httpsbackend" {
  name        = "httpsbackend"
  project     = "${var.project}"

  port_name = "nrehttps"
  protocol  = "HTTPS"

  timeout_sec = 10

  enable_cdn = false

  backend {
    group = "${data.google_compute_region_instance_group.workers.self_link}"
  }

  depends_on = [
    "google_compute_health_check.httpshealth",
  ]

  health_checks = [
    "${google_compute_health_check.httpshealth.self_link}",
  ]
}

resource "google_compute_backend_service" "observer-influxdb" {
  name        = "observer-influxdb"
  project     = "${var.project}"

  port_name = "observer-influxdb"
  protocol  = "HTTP"

  timeout_sec = 10

  enable_cdn = false

  backend {
    group = "${data.google_compute_instance_group.observer.self_link}"
  }

  depends_on = [
    "google_compute_health_check.observerhealth-influxdb",
  ]

  health_checks = [
    "${google_compute_health_check.observerhealth-influxdb.self_link}",
  ]
}

resource "google_compute_backend_service" "observer-grafana" {
  name        = "observer-grafana"
  project     = "${var.project}"

  port_name = "observer-grafana"
  protocol  = "HTTP"

  timeout_sec = 10

  enable_cdn = false

  backend {
    group = "${data.google_compute_instance_group.observer.self_link}"
  }

  depends_on = [
    "google_compute_health_check.observerhealth-grafana",
  ]

  health_checks = [
    "${google_compute_health_check.observerhealth-grafana.self_link}",
  ]
}



resource "google_compute_backend_service" "httpbackend" {
  name        = "httpbackend"
  project     = "${var.project}"

  port_name = "nrehttp"
  protocol  = "HTTP"

  timeout_sec = 10

  enable_cdn = false

  backend {
    group = "${data.google_compute_region_instance_group.workers.self_link}"
  }

  depends_on = [
    "google_compute_health_check.httphealth",
  ]

  health_checks = [
    "${google_compute_health_check.httphealth.self_link}",
  ]
}

resource "google_compute_health_check" "httphealth" {
  name    = "httphealth"
  project = "${var.project}"

  timeout_sec        = 1
  check_interval_sec = 3

  tcp_health_check {
    port = "30001"
  }
}

resource "google_compute_health_check" "observerhealth-influxdb" {
  name    = "observerhealth-influxdb"
  project = "${var.project}"

  timeout_sec        = 1
  check_interval_sec = 3

  tcp_health_check {
    port = "8086"
  }
}
resource "google_compute_health_check" "observerhealth-grafana" {
  name    = "observerhealth-grafana"
  project = "${var.project}"

  timeout_sec        = 1
  check_interval_sec = 3

  tcp_health_check {
    port = "3000"
  }
}


resource "google_compute_health_check" "httpshealth" {
  name    = "httpshealth"
  project = "${var.project}"

  timeout_sec        = 1
  check_interval_sec = 3

  tcp_health_check {
    port = "30002"
  }
}

resource "google_compute_backend_bucket" "maintenance" {
  name        = "maintenance"
  project = "${var.project}"
  bucket_name = "${google_storage_bucket.maintenance-page.name}"
  enable_cdn  = false
}


###################################
#    !!! OLD internal k8s api !!! #
###################################

resource "google_compute_forwarding_rule" "k8sapi" {
  name    = "k8sapi-forwarding-rule"
  project = "${var.project}"

  ip_address = "10.138.0.254"

  ports                 = ["6443"]
  load_balancing_scheme = "INTERNAL"
  backend_service       = "${google_compute_region_backend_service.k8sapi.self_link}"
  network               = "${google_compute_network.default-internal.name}"
}

resource "google_compute_region_backend_service" "k8sapi" {
  name        = "k8sapi"
  project     = "${var.project}"
  description = "k8sapi"

  # port_name = "k8sapi"
  protocol = "TCP"

  timeout_sec = 10

  # enable_cdn = false

  backend {
    group = "${data.google_compute_region_instance_group.controllers.self_link}"
  }
  depends_on = [
    "google_compute_health_check.k8sapi",
  ]
  health_checks = [
    "${google_compute_health_check.k8sapi.self_link}",
  ]
}

resource "google_compute_health_check" "k8sapi" {
  name    = "k8sapi"
  project = "${var.project}"

  timeout_sec        = 1
  check_interval_sec = 3

  tcp_health_check {
    port = "6443"
  }
}


############################
#   !!!!!   K8S HA !!!!    #
############################

# resource "google_compute_forwarding_rule" "k8s-ha" {
#   name       = "k8sapi-forwarding-rule-ha"
#   project    = "${var.project}"

#   ip_address = "10.138.0.250"
#   ports                 = ["6443"]
#   load_balancing_scheme = "INTERNAL"
#   backend_service       = "${google_compute_region_backend_service.k8sapi-ha.self_link}"
#   network               = "${google_compute_network.default-internal.name}"
# }

# resource "google_compute_region_backend_service" "k8sapi-ha" {
#   name        = "k8sapi-ha"
#   project     = "${var.project}"
#   description = "k8sapi-ha"

#   # port_name = "k8sapi"
#   protocol = "TCP"

#   timeout_sec = 10

#   # enable_cdn = false

#   backend {
#     group = "${data.google_compute_instance_group.controller-ha-group-0.self_link}"
#   }

#   # ONLY UNCOMMENT THESE AFTER THEY'VE BEEN JOINED TO THE CLUSTER
#   # You can't join to the load balancer IP from a group within the load balancer's control.
#   # Join first, then add to the load balancer with this.
#   #
#   # backend {
#   #   group = "${data.google_compute_instance_group.controller-ha-group-1.self_link}"
#   # }

#   # backend {
#   #   group = "${data.google_compute_instance_group.controller-ha-group-2.self_link}"
#   # }

#   depends_on = [
#     "google_compute_health_check.k8sapi-ha",
#   ]
#   health_checks = [
#     "${google_compute_health_check.k8sapi-ha.self_link}",
#   ]
# }

# resource "google_compute_health_check" "k8sapi-ha" {
#   name    = "k8sapi-ha"
#   project = "${var.project}"

#   timeout_sec        = 1
#   check_interval_sec = 3

#   tcp_health_check {
#     port = "6443"
#   }
# }
