# Configure the Google Cloud Provider
provider "google" {
  project = "absolute-bonsai-429218-u1"
  region  = "europe-west12"
  zone    = "europe-west12-b"
}

# Create a service account
resource "google_service_account" "kubernetes_sa" {
  account_id = "kubernetes-sa"
  display_name = "Service account for Kubernetes cluster"
}

# Grant the service account the necessary permissions
resource "google_project_iam_member" "kubernetes_sa_cluster_admin" {
  project = "absolute-bonsai-429218-u1"
  role    = "roles/container.clusterAdmin"
  member  = "serviceAccount:${google_service_account.kubernetes_sa.email}"
}

# Create a key file for the service account
resource "google_service_account_key" "kubernetes_sa_key" {
  service_account_id = google_service_account.kubernetes_sa.id
}

# Output the key file contents
output "kubernetes_sa_key" {
  value = base64decode(google_service_account_key.kubernetes_sa_key.private_key)
  sensitive = true
}

# Create a GKE cluster
resource "google_container_cluster" "primary" {
  name                     = "real-estate-listing-cluster"
  location                 = "europe-west12-b"
  initial_node_count       = 1
  remove_default_node_pool = true
  deletion_protection      = false

  # Ensure the cluster is not in autopilot mode
  autopilot {
    enabled = false
  }

  # Configure the node pool
  node_pool {
    name       = "real-estate-listing-node-pool"
    node_count = 1

    # Use e2-medium machine type
    node_config {
      machine_type = "e2-medium"
    }
  }

  # Ensure the cluster is public
  private_cluster_config {
    enable_private_nodes = false
  }

  # Specify the service account
  service_account {
    email  = google_service_account.kubernetes_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# Create a node pool with 1 or 2 nodes of type e2-medium
resource "google_container_node_pool" "primary_nodes" {
  name       = "real-estate-listing-node-pool"
  location   = "europe-west12"
  cluster    = google_container_cluster.primary.name
  node_count = 2

  # Use e2-medium machine type
  node_config {
    machine_type = "e2-medium"
  }
}
