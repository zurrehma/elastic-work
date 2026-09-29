provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "nodes" {
  name          = "${var.name}-nodes"
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = "10.50.0.0/20"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.52.0.0/14"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.56.0.0/20"
  }
}

resource "google_container_cluster" "this" {
  name     = var.name
  location = var.region

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.nodes.id

  # Node pool is managed separately so it can be resized or replaced on its own.
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }
}

resource "google_container_node_pool" "elastic" {
  name     = "elastic"
  cluster  = google_container_cluster.this.id
  location = var.region

  # Regional cluster: one node per zone (3 zones).
  node_count = 1

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = 50
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

data "google_client_config" "current" {}

provider "helm" {
  kubernetes = {
    host                   = "https://${google_container_cluster.this.endpoint}"
    token                  = data.google_client_config.current.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.this.master_auth[0].cluster_ca_certificate)
  }
}

module "eck" {
  source = "../../modules/eck"
  # GKE's default Persistent Disk CSI class (balanced PD).
  storage_class_name = "standard-rwo"

  depends_on = [google_container_node_pool.elastic]
}
