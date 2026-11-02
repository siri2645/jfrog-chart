
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "name" {
  description = "Cloud Armor security policy name"
  type        = string
}

variable "description" {
  description = "Cloud Armor security policy description"
  type        = string
  default     = "Cloud Armor security policy"
}

variable "rules" {
  description = "List of Cloud Armor security policy rules"

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
      (
        (rule.src_ip_ranges != null && rule.expression == null) ||
        (rule.src_ip_ranges == null && rule.expression != null)
      )
    ])

    error_message = "Each rule must contain either src_ip_ranges or expression."
  }

  validation {
    condition = (
      length(distinct([for rule in var.rules : rule.priority])) ==
      length(var.rules)
    )

    error_message = "Rule priorities must be unique."
  }

  validation {
    condition = alltrue([
      for rule in var.rules :
      contains(
        ["allow", "deny(403)", "deny(404)", "deny(502)"],
        rule.action
      )
    ])

    error_message = "Unsupported action. Use allow, deny(403), deny(404), or deny(502)."
  }
}
