# セットアップガイド

## 前提条件

以下のツールがインストールされている必要があります：

- **Google Cloud SDK (gcloud)**
  ```bash
  # macOS
  brew install google-cloud-sdk
  
  # Linux/WSL
  curl https://sdk.cloud.google.com | bash
  ```

- **Terraform**
  ```bash
  # macOS
  brew install terraform
  
  # Linux/WSL
  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update && sudo apt install terraform
  ```

- **jq**
  ```bash
  # macOS
  brew install jq
  
  # Linux/WSL
  sudo apt-get install jq
  ```

- **Claude Desktop**
  - [公式サイト](https://claude.ai/download)からダウンロード

## ステップバイステップ設定

### 1. プロジェクトの準備

```bash
# リポジトリのクローン
git clone https://github.com/YOUR_USERNAME/mcp-toolbox-bigquery.git
cd mcp-toolbox-bigquery

# 初期化スクリプトの実行
./scripts/init-project.sh YOUR-PROJECT-ID
```

### 2. Google Cloudプロジェクトの設定

```bash
# プロジェクトの作成（新規の場合）
gcloud projects create YOUR-PROJECT-ID --name="MCP Toolbox"

# 課金アカウントのリンク
gcloud billing accounts list
gcloud billing projects link YOUR-PROJECT-ID --billing-account=BILLING-ACCOUNT-ID

# プロジェクトの設定
gcloud config set project YOUR-PROJECT-ID
```

### 3. Terraformによるインフラ構築

```bash
# 初期化
make init

# 変更内容の確認
make plan

# インフラ構築
make apply
```

出力される情報をメモしてください：
- `service_url`: Cloud RunサービスのURL
- `client_sa_email`: クライアント用サービスアカウント
- `github_wif_provider`: GitHub Actions用Provider
- `github_sa_email`: GitHub Actions用サービスアカウント

### 4. GitHubリポジトリの設定

#### リポジトリの作成

```bash
# GitHubでリポジトリ作成後
git remote add origin https://github.com/YOUR_USERNAME/mcp-toolbox-bigquery.git
git branch -M main
git push -u origin main
```

#### GitHub Secretsの設定

GitHubリポジトリの Settings → Secrets and variables → Actions で以下を設定：

- `GCP_PROJECT_ID`: あなたのプロジェクトID
- `WIF_PROVIDER`: Terraformの`github_wif_provider`出力値
- `WIF_SERVICE_ACCOUNT`: Terraformの`github_sa_email`出力値

### 5. アプリケーションのデプロイ

```bash
# Cloud Buildを使用してデプロイ
make deploy

# または GitHub Actionsを使用
git add .
git commit -m "Deploy MCP Toolbox"
git push origin main
```

### 6. Claude Desktopの設定

```bash
# クライアント設定スクリプトの実行
make client

# または手動実行
cd client
./setup.sh
```

### 7. 動作確認

1. Claude Desktopを再起動
2. 入力欄に🔨アイコンが表示されることを確認
3. 以下のクエリをテスト：
   - "What BigQuery datasets are available?"
   - "List all tables in dataset X"
   - "Show me the schema of table Y"

## トラブルシューティング

### APIが有効化されていないエラー

```bash
# 必要なAPIを手動で有効化
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  bigquery.googleapis.com \
  iamcredentials.googleapis.com
```

### 権限エラー

```bash
# 現在のユーザーに必要な権限を付与
gcloud projects add-iam-policy-binding YOUR-PROJECT-ID \
  --member="user:YOUR-EMAIL" \
  --role="roles/owner"
```

### Cloud Runエラー

```bash
# ログの確認
make logs

# サービスの状態確認
gcloud run services describe mcp-toolbox-bigquery \
  --region=asia-northeast1
```

## 次のステップ

- [運用ガイド](operations.md)を参照
- [トラブルシューティング](troubleshooting.md)を参照
- BigQueryにデータセットを作成してテスト