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

# 既存のサービスアカウント（MCP Toolbox用）を参照
data "google_service_account" "mcp_toolbox" {
  project    = local.project_id
  account_id = "mcp-toolbox-sa@${local.project_id}.iam.gserviceaccount.com"
}

# BigQuery権限
resource "google_project_iam_member" "bigquery_permissions" {
  for_each = toset([
    "roles/bigquery.user",
    "roles/bigquery.dataViewer"
  ])
  
  project = local.project_id
  role    = each.value
  member  = "serviceAccount:${data.google_service_account.mcp_toolbox.email}"
}

# 既存のCloud Runサービスを参照
data "google_cloud_run_v2_service" "main" {
  project  = local.project_id
  name     = var.service_name
  location = local.region
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