terraform {
  backend "local" {
    # ローカルステート管理（小規模プロジェクト向け）
    # 本番環境ではGCSバックエンドを推奨：
    # backend "gcs" {
    #   bucket = "terraform-state-YOUR-PROJECT-ID"
    #   prefix = "mcp-toolbox"
    # }
  }
}