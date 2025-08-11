# API Gateway リソース
# 注意: これらのリソースは手動で作成済み（terraform importで管理下に置く）

resource "google_api_gateway_api" "main" {
  provider     = google-beta
  project      = local.project_id
  api_id       = "mcp-toolbox-api"
  display_name = "mcp-toolbox-api"
}

resource "google_api_gateway_api_config" "main" {
  provider      = google-beta
  project       = local.project_id
  api           = google_api_gateway_api.main.api_id
  api_config_id = "mcp-toolbox-config"
  display_name  = "mcp-toolbox-config"

  openapi_documents {
    document {
      path     = "spec.yaml"
      contents = filebase64("${path.module}/../api-gateway/openapi-spec.yaml")
    }
  }

  gateway_config {
    backend_config {
      google_service_account = google_service_account.mcp_toolbox.email
    }
  }

  lifecycle {
    ignore_changes = [
      openapi_documents,
      gateway_config
    ]
  }
}

resource "google_api_gateway_gateway" "main" {
  provider    = google-beta
  project     = local.project_id
  gateway_id  = "mcp-toolbox-gateway"
  api_config  = google_api_gateway_api_config.main.id
  region      = local.region
  display_name = "mcp-toolbox-gateway"

  lifecycle {
    ignore_changes = [
      api_config
    ]
  }
}

# API Keys
resource "google_apikeys_key" "mcp_toolbox" {
  project      = local.project_id
  name         = "mcp-toolbox-key"
  display_name = "MCP Toolbox API Key"

  restrictions {
    api_targets {
      service = "mcp-toolbox-api-39k05kju0hgko.apigateway.trans-grid-245207.cloud.goog"
    }
  }

  lifecycle {
    ignore_changes = [
      name,
      restrictions
    ]
  }
}