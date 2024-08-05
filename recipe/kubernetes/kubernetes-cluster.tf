provider "google" {
  project = "recipe-sharing-platform-431401"
  region  = "europe-west12"
  zone    = "europe-west12-b"
}

resource "google_container_cluster" "primary" {
  name                     = "recipe-sharing-platform-cluster"
  location                 = "europe-west12-b"
  initial_node_count       = 1
  deletion_protection      = false

  network = "default"

  resource_labels = {
    environment = "dev"
  }

  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "10.0.0.0/28"
  }

  release_channel {
    channel = "REGULAR"
  }

  addons_config {
    http_load_balancing {
      disabled = true
    }
  }

  timeouts {
    create = "30m"
    update = "40m"
    delete = "20m"
  }
}

resource "google_container_node_pool" "primary_nodes" {
  cluster    = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location
  name       = "primary-node-pool"
  node_count = 2

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 70

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      environment = "dev"
    }

    tags = ["http-server", "https-server", "db-server", "mq-server"]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}