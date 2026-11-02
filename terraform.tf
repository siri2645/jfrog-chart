
module "cloud_armor" {

  source = "../"

  project_id = var.project_id

  name = "sandbox-cloud-armor"

  description = "Cloud Armor security policy for sandbox environment"

  rules = var.rules
}
