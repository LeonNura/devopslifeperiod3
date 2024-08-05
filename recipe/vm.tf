provider "google" {
  project = "recipe-sharing-platform-431401"
  region  = "europe-west12"
  zone    = "europe-west12-b"
}

resource "google_compute_instance" "default" {
  name         = "recipe-sharing-vm"
  machine_type = "e2-standard-4" # Updated machine type with more vCPUs and RAM

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 50
    }
  }

  network_interface {
    network = "default"

    access_config {
    }
  }

  tags = ["http-server", "https-server", "db-server", "mq-server", "redis-server", "monitoring-server"]

  metadata_startup_script = <<-EOF
    # Update and install Docker
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker

    # Add user to Docker group
    sudo usermod -aG docker $USER

    # Pull and run Redis container
    sudo docker pull redis
    sudo docker run -d --name redis -p 6379:6379 redis

    # Pull and run Prometheus container
    sudo docker pull prom/prometheus
    sudo docker run -d --name prometheus -p 9090:9090 prom/prometheus

    # Pull and run Grafana container
    sudo docker pull grafana/grafana
    sudo docker run -d --name grafana -p 3000:3000 grafana/grafana
  EOF
}

# Configure firewall rules to allow HTTP, HTTPS, Redis, Prometheus, and Grafana traffic
resource "google_compute_firewall" "default" {
  name    = "allow-http-https-db-mq-vm-monitoring"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "5432", "3306", "5672", "15672", "9092", "2181", "22", "6379", "3000", "9090"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["http-server", "https-server", "db-server", "mq-server", "redis-server", "monitoring-server"]
}
