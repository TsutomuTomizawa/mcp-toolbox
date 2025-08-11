# プロジェクト設定
locals {
  project_id = var.project_id
  region     = var.region
  
  # 必要なAPIリスト
  apis = [
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

# APIの有効化
resource "google_project_service" "apis" {
  for_each = toset(local.apis)
  
  project = local.project_id
  service = each.value
  
  disable_on_destroy = false
}

# Artifact Registry
resource "google_artifact_registry_repository" "main" {
  project       = local.project_id
  location      = local.region
  repository_id = "mcp-toolbox"
  description   = "MCP Toolbox Docker images"
  format        = "DOCKER"
  
  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }
}

# サービスアカウント（MCP Toolbox用）
resource "google_service_account" "mcp_toolbox" {
  project      = local.project_id
  account_id   = "mcp-toolbox-sa"
  display_name = "MCP Toolbox Service Account"
}

# BigQuery権限
resource "google_project_iam_member" "bigquery_permissions" {
  for_each = toset([
    "roles/bigquery.user",
    "roles/bigquery.dataViewer"
  ])
  
  project = local.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.mcp_toolbox.email}"
}

# Cloud Runサービス
resource "google_cloud_run_v2_service" "main" {
  project  = local.project_id
  name     = var.service_name
  location = local.region
  
  template {
    service_account = google_service_account.mcp_toolbox.email
    
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }
    
    containers {
      image = "${local.region}-docker.pkg.dev/${local.project_id}/mcp-toolbox/${var.service_name}:latest"
      
      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }
      
      env {
        name  = "GCP_PROJECT_ID"
        value = local.project_id
      }
      
      env {
        name  = "BQ_LOCATION"
        value = var.bq_location
      }
      
      ports {
        container_port = 8080
      }
    }
  }
  
  depends_on = [
    google_artifact_registry_repository.main,
    google_project_service.apis
  ]
}

# クライアント用サービスアカウント
resource "google_service_account" "client" {
  project      = local.project_id
  account_id   = "mcp-toolbox-client"
  display_name = "MCP Toolbox Client"
}

# Cloud Run呼び出し権限
resource "google_cloud_run_service_iam_member" "client_invoker" {
  project  = google_cloud_run_v2_service.main.project
  location = google_cloud_run_v2_service.main.location
  service  = google_cloud_run_v2_service.main.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.client.email}"
}

# GitHub Actions用サービスアカウント
resource "google_service_account" "github_actions" {
  project      = local.project_id
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions Service Account"
}

# GitHub Actions用の権限
resource "google_project_iam_member" "github_actions_permissions" {
  for_each = toset([
    "roles/run.admin",
    "roles/artifactregistry.writer",
    "roles/cloudbuild.builds.builder"
  ])
  
  project = local.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}