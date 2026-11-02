module "cloud_armor" {
  source = "../"

  project_id  = "YOUR_GCP_PROJECT_ID"
  name        = "application-cloud-armor"
  description = "Cloud Armor policy for application protection"

  rules = [
    {
      priority    = 1000
      action      = "deny(403)"
      description = "Block SQL injection"

      expression = "evaluatePreconfiguredWaf('sqli-v33-stable')"
    },
    {
      priority      = 2147483647
      action        = "allow"
      description   = "Default allow rule"
      src_ip_ranges = ["*"]
    }
  ]
}
