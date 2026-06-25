output "cluster_name" {
  description = "GKE cluster name."
  value       = google_container_cluster.platform_lab_cluster.name
}

output "cluster_location" {
  description = "GKE cluster location."
  value       = google_container_cluster.platform_lab_cluster.location
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository name."
  value       = google_artifact_registry_repository.platform_lab_repo.repository_id
}

output "artifact_registry_location" {
  description = "Artifact Registry location."
  value       = google_artifact_registry_repository.platform_lab_repo.location
}

output "artifact_registry_hostname" {
  description = "Artifact Registry Docker hostname."
  value       = "${var.region}-docker.pkg.dev"
}