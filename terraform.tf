variable "project_id" {
  description = "The GCP project ID where the Cloud Armor policy will be created."
  type        = string
}

variable "name" {
  description = "Name of the Cloud Armor security policy."
  type        = string
}

variable "description" {
  description = "Description of the Cloud Armor security policy."
  type        = string
  default     = "Managed by Terraform"
}

variable "type" {
  description = "Type of Cloud Armor security policy."
  type        = string
  default     = "CLOUD_ARMOR"

  validation {
    condition = contains([
      "CLOUD_ARMOR",
      "CLOUD_ARMOR_EDGE",
      "CLOUD_ARMOR_INTERNAL_SERVICE"
    ], var.type)

    error_message = "The policy type must be CLOUD_ARMOR, CLOUD_ARMOR_EDGE, or CLOUD_ARMOR_INTERNAL_SERVICE."
  }
}

variable "rules" {
  description = "List of Cloud Armor security policy rules."

  type = list(object({
    priority       = number
    action         = string
    description    = optional(string, "")
    preview        = optional(bool, false)
    src_ip_ranges  = optional(list(string))
    expression     = optional(string)
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
