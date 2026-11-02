module "cloud_armor" {
  source = "../"

  project_id = "your-gcp-project-id"
  name       = "sandbox-cloud-armor"

  description = "Cloud Armor security policy for sandbox"

  rules = var.rules
}
