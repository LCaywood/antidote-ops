# OLD
# ns-cloud-e1.googledomains.com
# ns-cloud-e2.googledomains.com
# ns-cloud-e3.googledomains.com
# ns-cloud-e4.googledomains.com

# NEW 


provider "cloudflare" {
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
}

resource "cloudflare_zone" "prod" {
  zone = "networkreliability.engineering"
}

resource "cloudflare_zone_settings_override" "zone-settings" {
  name = "networkreliability.engineering"  //TODO this should be available by reference
  settings {
    always_use_https = "on"
    automatic_https_rewrites = "off"
    ssl = "full"
  }
}


resource "cloudflare_load_balancer" "prod-lb" {
  zone = "networkreliability.engineering"  //TODO this should be available by reference
  name = "packet.labs.networkreliability.engineering"  //TODO this should be derived by reference
  fallback_pool_id = "${cloudflare_load_balancer_pool.prod-pool.id}"
  default_pool_ids = ["${cloudflare_load_balancer_pool.prod-pool.id}"]
  description = "production LB"
  proxied = true
  # depends_on = [
  #   "cloudflare_record.labs",
  # ]
}

resource "cloudflare_load_balancer_pool" "prod-pool" {
  name = "prod-pool"
  monitor = "${cloudflare_load_balancer_monitor.antidote-monitor.id}"
  origins {
    name = "antidote-worker-0"
    address = "antidote-worker-0.labs.networkreliability.engineering"
    enabled = true
  }
  origins {
    name = "antidote-worker-1"
    address = "antidote-worker-1.labs.networkreliability.engineering"
    enabled = true
  }
  origins {
    name = "antidote-worker-2"
    address = "antidote-worker-2.labs.networkreliability.engineering"
    enabled = true
  }
}

resource "cloudflare_load_balancer_monitor" "antidote-monitor" {
  expected_body = ""
  expected_codes = "2xx"
  method = "GET"
  type = "https"
  timeout = 7
  path = "/"
  interval = 60
  retries = 5
  port = 30002
  description = "antidote https health check"
#   header {
#     header = "Host"
#     values = ["packet.labs.networkreliability.engineering"]
#   }
  allow_insecure = true
  follow_redirects = true
}
    
resource "cloudflare_record" "netlify" {
  domain = "networkreliability.engineering"
  name = "networkreliability.engineering"
  value  = "104.198.14.52"
  type   = "A"
  ttl    = 300
}

resource "cloudflare_record" "netlify_www" {
  domain = "networkreliability.engineering"
  name = "www.networkreliability.engineering"
  value  = "104.198.14.52"
  type   = "A"
  ttl    = 300
}

# resource "cloudflare_record" "root2" {
#   domain = "networkreliability.engineering"
#   name = "networkreliability.engineering"
#   value  = "185.199.109.153"
#   type   = "A"
#   ttl    = 300
# }

# resource "cloudflare_record" "root3" {
#   domain = "networkreliability.engineering"
#   name = "networkreliability.engineering"
#   value  = "185.199.110.153"
#   type   = "A"
#   ttl    = 300
# }

# resource "cloudflare_record" "root4" {
#   domain = "networkreliability.engineering"
#   name = "networkreliability.engineering"
#   value  = "185.199.111.153"
#   type   = "A"
#   ttl    = 300
# }

resource "cloudflare_record" "labs" {
  domain = "networkreliability.engineering"
  name = "labs.networkreliability.engineering"
  value  = "${google_compute_global_address.nrefrontend.address}"
  type   = "A"
  ttl    = 300
}


resource "cloudflare_record" "ptr" {
  domain = "networkreliability.engineering"
  name = "ptr.labs.networkreliability.engineering"
  value  = "${google_compute_global_address.nrefrontend.address}"
  type   = "A"
  ttl    = 300
}

resource "cloudflare_record" "bypassmaint" {
  domain = "networkreliability.engineering"
  name = "maintbypass.labs.networkreliability.engineering"
  value  = "${google_compute_global_address.nrefrontend.address}"
  type   = "A"
  ttl    = 300
}


resource "cloudflare_record" "abathur" {
  domain = "networkreliability.engineering"
  name = "abathur.networkreliability.engineering"
  value  = "${google_compute_instance.abathur.network_interface.0.access_config.0.nat_ip}"
  type   = "A"
  ttl    = 300
}

resource "cloudflare_record" "influxdb" {
  domain = "networkreliability.engineering"
  name = "influxdb.networkreliability.engineering"
  type = "A"
  ttl  = 300
  value = "${google_compute_global_address.nrefrontend.address}"
}

resource "cloudflare_record" "grafana" {
  domain = "networkreliability.engineering"
  name = "grafana.networkreliability.engineering"
  type = "A"
  ttl  = 300
  value = "${google_compute_global_address.nrefrontend.address}"
}

resource "cloudflare_record" "community" {
  domain = "networkreliability.engineering"
  name = "community.networkreliability.engineering"
  value  = "networkreliability.hosted-by-discourse.com"
  type   = "CNAME"
  ttl    = 300
}

# -----------------------------------------------------

# resource "google_dns_record_set" "lily" {
#   name = "lily.networkreliability.engineering."
#   type = "A"
#   ttl  = 300
#   project = "${var.project}"
#   managed_zone = "nre"
#   rrdatas = [
#     "${packet_device.lily.network.0.address}",
#   ]
# }
# resource "google_dns_record_set" "packet" {
#   name = "packet.labs.networkreliability.engineering."
#   type = "A"
#   ttl  = 300
#   project = "${var.project}"
#   managed_zone = "nre"
#   rrdatas = [
#     "${packet_device.antidote-worker.0.network.0.address}",
#     "${packet_device.antidote-worker.1.network.0.address}",
#     "${packet_device.antidote-worker.2.network.0.address}",
#   ]
# }


# Re-enable once you have these up

# resource "cloudflare_record" "lily" {
#   domain = "networkreliability.engineering"
#   name = "lily.networkreliability.engineering"
#   value  = "${packet_device.lily.network.0.address}"
#   type   = "A"
#   ttl    = 300
# }

# // convert these to the new for each resource syntax when it's released.
# //https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each

# resource "cloudflare_record" "packetworker0" {
#   domain = "networkreliability.engineering"
#   name = "antidote-worker-0.labs.networkreliability.engineering"
#   value  = "${packet_device.antidote-worker.0.network.0.address}"
#   type   = "A"
#   ttl    = 300
# }


# resource "cloudflare_record" "packetworker1" {
#   domain = "networkreliability.engineering"
#   name = "antidote-worker-1.labs.networkreliability.engineering"
#   value  = "${packet_device.antidote-worker.1.network.0.address}"
#   type   = "A"
#   ttl    = 300
# }


# resource "cloudflare_record" "packetworker2" {
#   domain = "networkreliability.engineering"
#   name = "antidote-worker-2.labs.networkreliability.engineering"
#   value  = "${packet_device.antidote-worker.2.network.0.address}"
#   type   = "A"
#   ttl    = 300
# }

