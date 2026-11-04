variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "security_policy_name" {
  description = "Name of the Cloud Armor security policy."
  type        = string
}

variable "description" {
  description = "Description of the Cloud Armor security policy."
  type        = string
  default     = "Managed by Terraform"
}

# Cloud Armor security policy type
variable "security_policy_type" {
  description = "Type of the Cloud Armor security policy."
  type        = string
  default     = "CLOUD_ARMOR"

  validation {
    condition = contains([
      "CLOUD_ARMOR",
      "CLOUD_ARMOR_EDGE",
      "CLOUD_ARMOR_INTERNAL_SERVICE"
    ], var.security_policy_type)

    error_message = "Valid types are CLOUD_ARMOR, CLOUD_ARMOR_EDGE, or CLOUD_ARMOR_INTERNAL_SERVICE."
  }
}

# Deletion policy
variable "deletion_policy" {
  description = "Deletion behavior of the Cloud Armor security policy."
  type        = string
  default     = "DELETE"

  validation {
    condition = contains([
      "DELETE",
      "PREVENT",
      "ABANDON"
    ], var.deletion_policy)

    error_message = "Valid deletion policies are DELETE, PREVENT, or ABANDON."
  }
}

# Labels
variable "labels" {
  description = "Labels to apply to the Cloud Armor security policy."
  type        = map(string)
  default     = {}
}

# Existing rules variable
variable "rules" {
  description = "Cloud Armor security policy rules."

  type = list(object({
    priority     = number
    action       = string
    description  = optional(string, "")
    preview      = optional(bool, false)
    src_ip_ranges = optional(list(string))
    expression   = optional(string)
  }))

  validation {
    condition = alltrue([
      for rule in var.rules :
      (rule.src_ip_ranges != null) != (rule.expression != null)
    ])

    error_message = "Each rule must define exactly one of src_ip_ranges or expression."
  }

  validation {
    condition = length(distinct([
      for rule in var.rules : rule.priority
    ])) == length(var.rules)

    error_message = "Rule priorities must be unique."
  }
}
