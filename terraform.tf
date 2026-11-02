variable "rules" {
  description = "Cloud Armor security policy rules"

  type = list(object({
    priority      = number
    action        = string
    description   = optional(string, "")
    preview       = optional(bool, false)
    src_ip_ranges = optional(list(string))
    expression    = optional(string)
  }))
}
