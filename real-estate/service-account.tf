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
