provider "google" {
  version = "3.5.0"

  credentials = file("service-key-epam-test-306514.json")

  project = var.project
  region  = var.region
  zone    = var.zone
}



resource "google_compute_network" "vpc_network" {
  name = "new-terraform-network"
}
resource "google_compute_autoscaler" "epam_lb" {
  name   = "my-autoscaler"
  project = var.project
  zone   = var.zone
  target = google_compute_instance_group_manager.epam_lb.self_link

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_instance_template" "epam_lb" {
  name           = "my-instance-template"
  machine_type   = "n1-standard-1"
  can_ip_forward = false
  project = var.project
  tags = ["foo", "bar", "allow-lb-service"]

  disk {
    source_image = data.google_compute_image.centos_7.self_link
  }

  network_interface {
    network = "default"
  }

  metadata = {
    foo = "bar"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

module "lb" {
  source  = "GoogleCloudPlatform/lb/google"
  version = "2.2.0"
  region       = var.region
  name         = "load-balancer"
  service_port = 80
  target_tags  = ["my-target-pool"]
  network      = google_compute_network.vpc_network.name
}

resource "google_compute_target_pool" "epam_lb" {
  name = "my-target-pool"
  project = var.project
  region = var.region
}

//HERE IS MAGIC

resource "google_compute_ssl_policy" "custom-ssl-policy" {
  name            = "custom-ssl-policy"
  min_tls_version = "TLS_1_2"
  profile         = "MODERN"
}

resource "google_compute_instance_group_manager" "epam_lb" {
  name = "my-igm"
  zone = var.zone
  project = var.project
  version {
    instance_template  = google_compute_instance_template.epam_lb.self_link
    name               = "primary"
  }

  target_pools       = [google_compute_target_pool.epam_lb.self_link]
  base_instance_name = "terraform"
}

data "google_compute_image" "centos_7" {
  family  = "centos-7"
  project = "centos-cloud"
}