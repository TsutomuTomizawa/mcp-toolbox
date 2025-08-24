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

# 既存のArtifact Registryを参照
data "google_artifact_registry_repository" "main" {
  project       = local.project_id
  location      = local.region
  repository_id = "mcp-toolbox"
}

# MCP Toolbox用サービスアカウントの作成
resource "google_service_account" "mcp_toolbox" {
  project      = local.project_id
  account_id   = "mcp-toolbox-sa"
  display_name = "MCP Toolbox Service Account"
  description  = "Service account for MCP Toolbox Cloud Run service"
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

# Cloud Runサービスの作成
resource "google_cloud_run_v2_service" "main" {
  project  = local.project_id
  name     = var.service_name
  location = local.region
  
  template {
    service_account = google_service_account.mcp_toolbox.email
    
    scaling {
      min_instance_count = 1
      max_instance_count = 10
    }
    
    containers {
      image = "${local.region}-docker.pkg.dev/${local.project_id}/mcp-toolbox/${var.service_name}:latest"
      
      ports {
        container_port = 8080
      }
      
      env {
        name  = "GCP_PROJECT_ID"
        value = local.project_id
      }
      
      env {
        name  = "BQ_LOCATION"
        value = "asia-southeast2"
      }
      
      env {
        name  = "LOG_LEVEL"
        value = "INFO"
      }
      
      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }
    }
  }
  
  depends_on = [
    google_project_service.apis
  ]
}

# Cloud Runサービスへのパブリックアクセスを許可
resource "google_cloud_run_service_iam_member" "public_access" {
  project  = local.project_id
  location = local.region
  service  = google_cloud_run_v2_service.main.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# 既存のデプロイ用サービスアカウントを参照
data "google_service_account" "github_actions" {
  project    = local.project_id
  account_id = "mcp-toolbox-deploy@${local.project_id}.iam.gserviceaccount.com"
}

# GitHub Actions用の権限（既に付与済みの場合はスキップ）
resource "google_project_iam_member" "github_actions_permissions" {
  for_each = toset([
    "roles/run.admin",
    "roles/artifactregistry.writer",
    "roles/cloudbuild.builds.editor",
    "roles/iam.serviceAccountUser"
  ])
  
  project = local.project_id
  role    = each.value
  member  = "serviceAccount:${data.google_service_account.github_actions.email}"
}