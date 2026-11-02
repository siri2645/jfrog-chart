project_id       = "YOUR_GCP_PROJECT_ID"
cloud_armor_name = "sandbox-cloud-armor"

rules = [
  {
    priority    = 1000
    action      = "deny(403)"
    description = "Block SQL injection attacks"

    expression = "evaluatePreconfiguredWaf('sqli-v33-stable')"
  },
  {
    priority    = 1100
    action      = "deny(403)"
    description = "Block XSS attacks"
    preview     = true

    expression = "evaluatePreconfiguredWaf('xss-v33-stable')"
  },
  {
    priority      = 1200
    action        = "deny(403)"
    description   = "Block specified IP address"
    src_ip_ranges = ["192.0.2.10/32"]
  },
  {
    priority      = 2147483647
    action        = "allow"
    description   = "Default allow rule"
    src_ip_ranges = ["*"]
  }
]
