output "service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.main.uri
}

output "deploy_sa_email" {
  description = "Deploy service account email"
  value       = google_service_account.github_actions.email
}