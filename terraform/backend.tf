terraform {
  backend "gcs" {
    bucket = "terraform-state-expertduck"
    prefix = "mcp-toolbox"
  }
}