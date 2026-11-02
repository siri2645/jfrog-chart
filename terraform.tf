variable "project_id" {
  description = "GCP project ID."
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

variable "rules" {
  description = "Cloud Armor security policy rules."

  type = list(object({
    priority      = number
    action        = string
    description   = optional(string, "")
    preview       = optional(bool, false)
    src_ip_ranges = optional(list(string))
    expression    = optional(string)
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
