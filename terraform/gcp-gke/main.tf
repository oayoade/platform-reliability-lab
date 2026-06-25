resource "google_compute_network" "platform_lab_vpc" {
  name                    = "platform-lab-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "platform_lab_subnet" {
  name          = "platform-lab-subnet"
  ip_cidr_range = "10.10.0.0/20"
  region        = var.region
  network       = google_compute_network.platform_lab_vpc.id

  secondary_ip_range {
    range_name    = "platform-lab-pods"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "platform-lab-services"
    ip_cidr_range = "10.30.0.0/20"
  }
}

resource "google_artifact_registry_repository" "platform_lab_repo" {
  location      = var.region
  repository_id = var.artifact_repository
  description   = "Docker repository for Platform Reliability Lab"
  format        = "DOCKER"
}

resource "google_service_account" "gke_nodes" {
  account_id   = "platform-lab-gke-nodes"
  display_name = "Platform Lab GKE Nodes"
}

resource "google_project_iam_member" "gke_nodes_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_container_cluster" "platform_lab_cluster" {
  name     = var.cluster_name
  location = var.zone

  network    = google_compute_network.platform_lab_vpc.id
  subnetwork = google_compute_subnetwork.platform_lab_subnet.id

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = "platform-lab-pods"
    services_secondary_range_name = "platform-lab-services"
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "platform_lab_nodes" {
  name     = "platform-lab-node-pool"
  location = var.zone
  cluster  = google_container_cluster.platform_lab_cluster.name

  node_count = var.node_count

  node_config {
    machine_type    = var.node_machine_type
    service_account = google_service_account.gke_nodes.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = "training"
      project     = "platform-lab"
    }

    tags = [
      "platform-lab-gke-node"
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}