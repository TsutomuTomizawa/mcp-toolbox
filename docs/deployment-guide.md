# デプロイメントガイド

このドキュメントでは、MCP ToolboxをGoogle Cloud Runにデプロイする手順を詳細に説明します。

## 前提条件

- Google Cloud プロジェクト（プロジェクトID: `trans-grid-245207`）
- gcloud CLI がインストール済み
- Terraform がインストール済み
- GitHub リポジトリ（`1900film/mcp-toolbox`）

## デプロイメントアーキテクチャ

```
GitHub Repository
   ├─→ GitHub Actions (terraform.yml)
   │      ↓
   │   Terraform Apply → GCP Infrastructure
   │                      (Cloud Run, IAM, etc.)
   │
   └─→ GitHub Actions (deploy.yml)
          ↓
       Cloud Build → Artifact Registry → Cloud Run
                                            ↓
                                         BigQuery
```

### デプロイフロー

1. **インフラ構築**: `terraform/`への変更 → GitHub Actions → Terraform Apply
2. **アプリデプロイ**: `server/`への変更 → GitHub Actions → Cloud Build → Cloud Run

## 1. 初期セットアップ

### 1.1 Google Cloud認証

```bash
# Google Cloudにログイン
gcloud auth login

# プロジェクトを設定
gcloud config set project trans-grid-245207
```

### 1.2 必要なAPIを有効化

```bash
# Terraformが自動的に有効化しますが、手動で行う場合
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable iamcredentials.googleapis.com
```

## 2. Terraformによるインフラストラクチャ構築

### 2.1 Terraform Stateバケットの作成（初回のみ）

```bash
# Terraform state用のGCSバケットを作成
gsutil mb -p trans-grid-245207 -l asia-northeast1 \
  gs://terraform-state-trans-grid-245207/
```

### 2.2 GitHub Actionsから自動実行

Terraformは**GitHub Actions経由で自動実行**されます：

1. `terraform/`ディレクトリのファイルを変更
2. mainブランチにプッシュ
3. 自動的にTerraform applyが実行される

```bash
# terraform/ディレクトリのファイルを変更後
git add terraform/
git commit -m "Update infrastructure"
git push origin main

# GitHub Actionsで自動的に以下が実行される：
# - terraform init
# - terraform plan
# - terraform apply (mainブランチのみ)
```

### 2.3 手動実行（オプション）

ローカルから手動で実行する場合：

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2.4 作成されるリソース

- **Artifact Registry**: Dockerイメージ保存用
- **Cloud Runサービス**: `mcp-toolbox`
- **サービスアカウント**: 
  - `mcp-toolbox-sa`: Cloud Run用（BigQuery読み取り権限）
  - `github-actions-sa`: GitHub Actions用（CI/CD）

## 3. GitHub Actions設定

### 3.1 サービスアカウントキーの生成

```bash
# Terraformでサービスアカウントを作成後、キーを生成
cd terraform
SERVICE_ACCOUNT=$(terraform output -raw github_sa_email)
cd ..

# キーファイルを生成
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account="${SERVICE_ACCOUNT}"

# 生成されたキーの内容を確認
cat github-actions-key.json
```

### 3.2 GitHub Secretsの設定

GitHub Secretsに以下の値を設定：

| Secret名 | 値 |
|---------|-----|
| `GCP_PROJECT_ID` | `trans-grid-245207` |
| `GCP_SA_KEY` | 上記で生成したJSONキーの内容全体 |

#### 設定方法1: GitHub Web UI
1. リポジトリの Settings → Secrets and variables → Actions
2. "New repository secret" をクリック
3. `GCP_PROJECT_ID` と `GCP_SA_KEY` を設定

#### 設定方法2: GitHub CLI
```bash
# プロジェクトIDを設定
gh secret set GCP_PROJECT_ID --body="trans-grid-245207"

# サービスアカウントキーを設定
gh secret set GCP_SA_KEY < github-actions-key.json

# キーファイルを安全に削除
rm github-actions-key.json
```

## 4. デプロイ実行

### 4.1 自動デプロイ（GitHub Actions）

mainブランチへのプッシュで自動デプロイ：

```bash
git add .
git commit -m "Deploy to Cloud Run"
git push origin main
```

### 4.2 手動デプロイ（Cloud Build）

```bash
cd server
gcloud builds submit --config cloudbuild.yaml
```

### 4.3 Makefileを使用

```bash
# 完全なセットアップ（初回）
make all

# アプリケーションのデプロイのみ
make deploy
```

## 5. デプロイ確認

### 5.1 Cloud Runサービスの確認

```bash
# サービスの状態確認
gcloud run services describe mcp-toolbox \
  --region=asia-northeast1

# URLの取得
gcloud run services describe mcp-toolbox \
  --region=asia-northeast1 \
  --format='value(status.url)'
```

### 5.2 ログの確認

```bash
# Cloud Runのログ
gcloud run logs read mcp-toolbox \
  --region=asia-northeast1 \
  --limit=50

# または
make logs
```

### 5.3 ヘルスチェック

```bash
# サービスURLを取得して確認
SERVICE_URL=$(gcloud run services describe mcp-toolbox \
  --region=asia-northeast1 \
  --format='value(status.url)')

# MCPエンドポイントテスト
curl -X POST ${SERVICE_URL}/mcp \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}'
```

## 6. Cloud Run接続設定

### 6.1 サービスURLの取得

```bash
# サービスURLを取得
SERVICE_URL=$(gcloud run services describe mcp-toolbox \
  --region=asia-northeast1 \
  --format='value(status.url)')

echo "Service URL: $SERVICE_URL"
```

### 6.2 認証トークンの取得（テスト用）

```bash
# IDトークンを取得（テスト用）
TOKEN=$(gcloud auth print-identity-token)

# APIテスト
curl -X POST ${SERVICE_URL}/mcp \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}'
```

## 7. トラブルシューティング

### Cloud Runが起動しない

```bash
# デプロイの詳細を確認
gcloud run revisions list --service=mcp-toolbox \
  --region=asia-northeast1

# 最新リビジョンのログ
gcloud run logs read mcp-toolbox \
  --region=asia-northeast1 \
  --limit=100
```

### 認証エラー

```bash
# サービスアカウントの権限確認
gcloud projects get-iam-policy trans-grid-245207 \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:mcp-toolbox*"
```

### GitHub Actions失敗

1. Actions タブで失敗したワークフローを確認
2. Workload Identity Federationの設定を確認
3. Secretsが正しく設定されているか確認

## 8. 環境変数

Cloud Runで使用される環境変数：

| 変数名 | 説明 | 値 |
|--------|------|-----|
| `GCP_PROJECT_ID` | Google CloudプロジェクトID | `trans-grid-245207` |
| `BQ_LOCATION` | BigQueryのロケーション | `asia-northeast1` |
| `LOG_LEVEL` | ログレベル | `info` / `debug` |

## 9. セキュリティ考慮事項

- Cloud Runは認証必須（デフォルト）
- サービスアカウントは最小権限の原則に従う
- BigQuery権限は読み取り専用（`roles/bigquery.dataViewer`）
- サービスアカウントキーは安全に管理（GitHub Secretsに保存）
- キーのローテーションを定期的に実施することを推奨

## 10. コスト最適化

- Cloud Run: 最小インスタンス数 = 0（リクエストがない時は0にスケール）
- 最大インスタンス数 = 10（トラフィックに応じて調整）
- CPU: 1 vCPU
- メモリ: 1GB