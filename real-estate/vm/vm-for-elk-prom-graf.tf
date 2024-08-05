provider "google" {
  project = "absolute-bonsai-429218-u1"
  region  = "europe-west12"
  zone    = "europe-west12-b"
}

resource "google_compute_instance" "default" {
  name         = "strong-vm-for-elk-prom-graf"
  machine_type = "e2-standard-4"

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

    # Pull and run Prometheus container
    sudo docker pull prom/prometheus
    sudo docker run -d --name prometheus -p 9090:9090 prom/prometheus

    # Pull and run Grafana container
    sudo docker pull grafana/grafana
    sudo docker run -d --name grafana -p 3000:3000 grafana/grafana

    # Pull and run Elasticsearch container
    docker run --name elasticsearch -d -p 9200:9200 -p 9300:9300 -e ELASTIC_PASSWORD=password -e discovery.type=single-node -e xpack.security.enabled=false -e xpack.security.http.ssl.enabled=false -e xpack.license.self_generated.type=trial -e network.host=0.0.0.0 docker.elastic.co/elasticsearch/elasticsearch:8.14.3
    # SHA256 Fingerprint=4B:45:65:2A:16:2A:5B:29:95:1C:0A:EB:B9:06:C6:6F:F9:1D:C2:D0:A8:74:69:6A:47:BC:1E:C6:66:7F:02:C2
    # ELASTIC_PASSWORD=password

    # Pull and run Kibana container
    sudo docker pull docker.elastic.co/kibana/kibana:7.17.0
    sudo docker run -d --name kibana -p 5601:5601 --link elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:7.17.0

    # Pull and run Alertmanager container
    sudo docker pull prom/alertmanager:v0.24.0
    sudo docker run -d --name alertmanager -p 9093:9093 prom/alertmanager:latest
  EOF
}

# Configure firewall rules to allow HTTP, HTTPS, Prometheus, Grafana, Elasticsearch, Kibana, and Alertmanager traffic
resource "google_compute_firewall" "default" {
  name    = "allow-http-https-db-mq-vm-monitoring-elk-prom-graf"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "5432", "3306", "5672", "15672", "9092", "2181", "22", "3000", "9090", "9200", "9300", "5601", "9093"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["http-server", "https-server", "db-server", "mq-server", "redis-server", "monitoring-server"]
}
