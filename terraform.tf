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
        versioned_expr = rule.value.src_ip_ranges != null ? "SRC_IPS_V1" : null

        dynamic "config" {
          for_each = rule.value.src_ip_ranges != null ? [rule.value.src_ip_ranges] : []

          content {
            src_ip_ranges = config.value
          }
        }

        dynamic "expr" {
          for_each = rule.value.expression != null ? [rule.value.expression] : []

          content {
            expression = expr.value
          }
        }
      }
    }
  }
}
