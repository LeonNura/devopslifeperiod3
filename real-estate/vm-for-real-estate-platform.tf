# Configure the Google Cloud provider
provider "google" {
  project = "absolute-bonsai-429218-u1"
  region  = "europe-west12"
  zone    = "europe-west12-b"
}

# Define the VM instance
resource "google_compute_instance" "default" {
  name         = "real-estate-listing-webapp-vm"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 40
    }
  }

  network_interface {
    network = "default"

    access_config {
    }
  }

  tags = ["http-server", "https-server", "db-server", "mq-server"]

  metadata_startup_script = <<-EOF
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker

    sudo usermod -aG docker $USER

    docker run -d --name my-postgres-container \
    -p 5432:5432 \
    -e POSTGRES_PASSWORD=GRhtx3rC \
    -e POSTGRES_USER=real-estate-platform-user \
    -e POSTGRES_DB=real-estate-platform \
    -v /var/lib/postgresql/data:/var/lib/postgresql/data \
    postgres:latest

    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: realestatedb
  EOF
}

# Configure firewall rules to allow HTTP and HTTPS traffic
resource "google_compute_firewall" "default" {
  name    = "allow-http-https-db-mq"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "5432", "3306", "5672", "15672", "9092", "2181", "22"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["http-server", "https-server", "db-server", "mq-server"]
}
