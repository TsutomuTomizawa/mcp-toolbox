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
  - `mcp-toolbox-sa`: Cloud Run実行用
    - `roles/bigquery.user`: BigQueryジョブ実行権限
    - `roles/bigquery.dataViewer`: BigQueryデータ読み取り権限
  - `mcp-toolbox-deploy`: デプロイ用（GitHub Actions/CI/CD）
    - `roles/run.admin`: Cloud Runデプロイ権限
    - `roles/artifactregistry.writer`: イメージプッシュ権限
    - `roles/cloudbuild.builds.builder`: ビルド実行権限

## 3. GitHub Actions設定

### 3.1 サービスアカウントの作成と権限設定

#### 方法1: Terraformで自動作成（推奨）
Terraformを実行すると自動的にサービスアカウントと権限が設定されます：

```bash
cd terraform
terraform init
terraform apply
```

#### 方法2: 手動作成
サービスアカウントを手動で作成する場合：

```bash
# サービスアカウントの作成
gcloud iam service-accounts create mcp-toolbox-deploy \
  --display-name="MCP Toolbox Deploy Service Account" \
  --project=trans-grid-245207

# 必要な権限を付与
PROJECT_ID=trans-grid-245207
SA_EMAIL=mcp-toolbox-deploy@${PROJECT_ID}.iam.gserviceaccount.com

# Cloud Run管理者権限（デプロイ用）
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/run.admin"

# Artifact Registry書き込み権限（Dockerイメージプッシュ用）
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/artifactregistry.writer"

# Cloud Buildビルダー権限（ビルド実行用）
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudbuild.builds.builder"
```

#### 必要な権限の詳細

| ロール | 用途 |
|--------|------|
| `roles/run.admin` | Cloud Runサービスのデプロイと管理 |
| `roles/artifactregistry.writer` | DockerイメージをArtifact Registryにプッシュ |
| `roles/cloudbuild.builds.builder` | Cloud Buildでビルドを実行 |

#### 権限の確認

```bash
# サービスアカウントに付与された権限を確認
gcloud projects get-iam-policy trans-grid-245207 \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:mcp-toolbox-deploy@trans-grid-245207.iam.gserviceaccount.com" \
  --format="table(bindings.role)"
```

### 3.2 サービスアカウントキーの生成

```bash
# キーファイルを生成（ローカルで実行）
gcloud iam service-accounts keys create deploy-key.json \
  --iam-account="mcp-toolbox-deploy@trans-grid-245207.iam.gserviceaccount.com"

# 生成されたキーの内容を表示（後でコピー用）
cat deploy-key.json
```

### 3.3 GitHub Secretsの登録（GUI）

#### 手順：
1. **GitHubリポジトリにアクセス**
   - https://github.com/1900film/mcp-toolbox

2. **Settings画面へ移動**
   - リポジトリの **Settings** タブをクリック
   - 左メニューの **Secrets and variables** → **Actions** を選択

3. **Secret 1: GCP_PROJECT_ID**
   - **New repository secret** ボタンをクリック
   - **Name**: `GCP_PROJECT_ID`
   - **Value**: `trans-grid-245207`
   - **Add secret** をクリック

4. **Secret 2: GCP_SA_KEY**
   - 再度 **New repository secret** ボタンをクリック
   - **Name**: `GCP_SA_KEY`
   - **Value**: 上記で生成した `deploy-key.json` の内容全体をコピー＆ペースト
   - **Add secret** をクリック

5. **登録確認**
   - Actions secrets ページに以下が表示されることを確認：
     - `GCP_PROJECT_ID`
     - `GCP_SA_KEY`

### 3.4 セキュリティ: キーファイルの削除

GitHub Secretsへの登録が完了したら、ローカルのキーファイルを削除：

```bash
# キーファイルを安全に削除
rm deploy-key.json

# 削除を確認
ls deploy-key.json 2>/dev/null || echo "✅ キーファイルが削除されました"
```

### 3.5 動作確認

Secretsが正しく設定されているか確認するには：

1. `terraform/` または `server/` ディレクトリのファイルを変更
2. mainブランチにプッシュ
3. **Actions** タブで実行状況を確認

```bash
# 例：READMEを更新してテスト
echo "# Test deployment" >> server/README.md
git add server/README.md
git commit -m "Test GitHub Actions deployment"
git push origin main

# GitHub Actionsの実行状況を確認
# https://github.com/1900film/mcp-toolbox/actions
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