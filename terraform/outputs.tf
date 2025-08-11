output "service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.main.uri
}

output "github_sa_email" {
  description = "GitHub Actions service account"
  value       = google_service_account.github_actions.email
}