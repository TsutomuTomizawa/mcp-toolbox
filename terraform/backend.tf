terraform {
  backend "gcs" {
    bucket = "terraform-state-trans-grid-245207"
    prefix = "mcp-toolbox"
  }
}