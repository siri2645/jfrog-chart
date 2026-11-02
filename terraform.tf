variable "project_id" {
  description = "GCP project ID for testing."
  type        = string
}

variable "cloud_armor_name" {
  description = "Name of the Cloud Armor policy."
  type        = string
}

variable "rules" {
  description = "Cloud Armor rules used for testing."

  type = list(object({
    priority      = number
    action        = string
    description   = optional(string, "")
    preview       = optional(bool, false)
    src_ip_ranges = optional(list(string))
    expression    = optional(string)
  }))
}

module "cloud_armor" {
  source = "../"

  project_id  = var.project_id
  name        = var.cloud_armor_name
  description = "Cloud Armor security policy managed through Terraform"
  type        = "CLOUD_ARMOR"
  rules       = var.rules
}

output "security_policy_id" {
  value = module.cloud_armor.security_policy_id
}

output "security_policy_name" {
  value = module.cloud_armor.security_policy_name
}

output "security_policy_self_link" {
  value = module.cloud_armor.security_policy_self_link
}
