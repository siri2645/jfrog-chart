
resource "google_compute_security_policy" "cloud_armor" {

  project     = var.project_id
  name        = var.name
  description = var.description
  type        = "CLOUD_ARMOR"

  dynamic "rule" {
    for_each = var.rules

    content {
      priority    = rule.value.priority
      action      = rule.value.action
      description = rule.value.description
      preview     = rule.value.preview

      match {

        versioned_expr = (
          try(rule.value.src_ip_ranges, null) != null
          ? "SRC_IPS_V1"
          : null
        )

        dynamic "config" {
          for_each = (
            try(rule.value.src_ip_ranges, null) != null
            ? [1] : []
          )

          content {
            src_ip_ranges = rule.value.src_ip_ranges
          }
        }

        dynamic "expr" {
          for_each = (
            try(rule.value.expression, null) != null
            ? [1] : []
          )

          content {
            expression = rule.value.expression
          }
        }
      }
    }
  }
}
