variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region."
  type        = string
  default     = "europe-west3"
}

variable "zone" {
  description = "The GCP zone."
  type        = string
  default     = "europe-west3-a"
}

variable "cluster_name" {
  description = "The GKE cluster name."
  type        = string
  default     = "platform-lab-gke"
}

variable "artifact_repository" {
  description = "Artifact Registry repository name."
  type        = string
  default     = "platform-lab"
}

variable "node_machine_type" {
  description = "Machine type for the GKE node pool."
  type        = string
  default     = "e2-standard-2"
}

variable "node_count" {
  description = "Number of nodes in the GKE node pool."
  type        = number
  default     = 1
}