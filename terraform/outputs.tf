output "service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.main.uri
}

output "client_sa_email" {
  description = "Client service account email"
  value       = google_service_account.client.email
}

output "github_wif_provider" {
  description = "GitHub Workload Identity Provider"
  value       = module.github_wif.provider_name
}

output "github_sa_email" {
  description = "GitHub Actions service account"
  value       = module.github_wif.service_account_email
}