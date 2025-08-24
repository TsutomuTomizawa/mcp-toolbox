# MCP Toolbox for BigQuery

Google Cloud上でBigQueryアクセスを提供するMCP (Model Context Protocol) サーバーの実装。  
Claude DesktopからCloud Run経由で直接BigQueryを操作できます。

## 🏗️ アーキテクチャ

```
Claude Desktop → mcp-remote → Cloud Run (MCP Toolbox) → BigQuery
```

### コンポーネント

- **Cloud Run**: MCP Toolboxサーバー（Google公式コンテナ）
- **BigQuery**: データウェアハウス
- **Terraform**: インフラストラクチャ管理
- **GitHub Actions**: CI/CDパイプライン

## 🚀 機能

- ✅ BigQueryへの読み取り専用アクセス
- ✅ SQLクエリ実行、テーブル/データセット一覧取得
- ✅ サーバーレスで自動スケーリング
- ✅ Claude Desktopとの完全統合
- ✅ GitHub Actions による自動デプロイ

## 📁 プロジェクト構造

```
.
├── docs/            # ドキュメント
│   ├── claude-desktop-setup.md
│   ├── deployment-guide.md
│   └── system-architecture.md
├── server/          # MCP Toolboxサーバー
│   ├── Dockerfile
│   ├── tools.yaml
│   └── cloudbuild.yaml
├── terraform/       # インフラストラクチャ定義
│   ├── main.tf
│   ├── backend.tf
│   └── variables.tf
├── .github/         # CI/CDワークフロー
│   └── workflows/
│       ├── deploy.yml    # アプリケーションデプロイ
│       └── terraform.yml # インフラ管理
└── CLAUDE.md        # Claude Code用プロジェクト説明
```

## 🔧 セットアップ

### 前提条件

- Google Cloud アカウント
- gcloud CLI インストール済み
- Terraform インストール済み（オプション）
- npm インストール済み（Claude Desktop用）
- GitHub アカウント

### 1. リポジトリのフォーク/クローン

```bash
# このリポジトリをフォークまたはクローン
git clone https://github.com/TsutomuTomizawa/mcp-toolbox.git
cd mcp-toolbox
```

### 2. Google Cloud設定

```bash
# Google Cloud認証
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# 必要なAPIを有効化
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  bigquery.googleapis.com \
  iam.googleapis.com
```

### 3. GitHub Secrets設定

リポジトリの Settings > Secrets and variables > Actions で以下を設定：

1. `GCP_PROJECT_ID`: あなたのGCPプロジェクトID
2. `GCP_SA_KEY`: デプロイ用サービスアカウントのキー（JSON）

詳細は [デプロイメントガイド](docs/deployment-guide.md) を参照。

### 4. 設定ファイルの更新

```bash
# プロジェクトIDを更新
sed -i '' 's/expertduck/YOUR_PROJECT_ID/g' server/tools.yaml
sed -i '' 's/expertduck/YOUR_PROJECT_ID/g' terraform/terraform.tfvars.example

# リージョンを必要に応じて更新（デフォルト: asia-southeast2）
sed -i '' 's/asia-southeast2/YOUR_REGION/g' .github/workflows/deploy.yml
```

### 5. デプロイ

#### 自動デプロイ（GitHub Actions）

```bash
git add .
git commit -m "Configure for my project"
git push origin main
```

#### 手動デプロイ

```bash
# Cloud Runへ直接デプロイ
gcloud run deploy mcp-toolbox \
  --image=us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:0.11.0 \
  --region=YOUR_REGION \
  --platform=managed \
  --allow-unauthenticated \
  --set-env-vars="GCP_PROJECT_ID=YOUR_PROJECT_ID,BQ_LOCATION=YOUR_REGION"
```

### 6. Claude Desktop設定

```json
{
  "mcpServers": {
    "mcp-toolbox-bigquery": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "YOUR_CLOUD_RUN_SERVICE_URL/mcp"
      ]
    }
  }
}
```

詳細は [Claude Desktop設定ガイド](docs/claude-desktop-setup.md) を参照。

## 📝 利用可能なMCPツール

| ツール名 | 説明 |
|---------|------|
| `query` | SQLクエリを実行 |
| `list-datasets` | データセット一覧を取得 |
| `list-tables` | テーブル一覧を取得 |
| `table-info` | テーブルメタデータを取得 |

## 🛠️ 開発・運用コマンド

### ローカル開発

```bash
# Dockerイメージをビルド
make local-build

# ローカルで起動
make local-start

# テストを実行
make local-test

# 停止
make local-stop
```

### インフラ管理（Terraform）

```bash
# 初期化
make init

# 実行計画を表示
make plan

# インフラをデプロイ
make apply

# インフラを削除
make destroy
```

### デプロイメント

```bash
# Cloud Runへデプロイ
make deploy

# ログを表示
make logs
```

## 🔐 セキュリティ

### アクセス制御

- **Cloud Run**: パブリックアクセス可能（認証不要）
- **BigQuery**: サービスアカウント経由で読み取り専用アクセス
- **最小権限**: 必要最小限の権限のみ付与

### セキュリティ機能

- ✅ BigQuery読み取り専用権限
- ✅ 最小権限の原則
- ✅ サービスアカウントによるアクセス制御
- ✅ 環境変数による設定管理

## ⚙️ 環境変数・設定

### 必須の環境変数

| 変数名 | 説明 | デフォルト |
|--------|------|-----------|
| `GCP_PROJECT_ID` | GCPプロジェクトID | - |
| `BQ_LOCATION` | BigQueryのロケーション | asia-southeast2 |

### GitHub Secrets（CI/CD用）

- `GCP_PROJECT_ID`: プロジェクトID
- `GCP_SA_KEY`: サービスアカウントキー（JSON）

## 📚 ドキュメント

- [Claude Desktop設定ガイド](docs/claude-desktop-setup.md) - Claude Desktopの詳細設定
- [デプロイメントガイド](docs/deployment-guide.md) - 本番環境へのデプロイ手順
- [システムアーキテクチャ](docs/system-architecture.md) - 技術的な詳細

## 🚨 トラブルシューティング

### Cloud Runエラー

```bash
# ログを確認
make logs

# サービスステータスを確認
gcloud run services describe mcp-toolbox --region=YOUR_REGION
```

### Terraform エラー

既存のリソースとの競合が発生した場合は、`terraform/main.tf` で既存リソースを data source として参照するよう修正してください。

## 🤝 コントリビューション

プルリクエストを歓迎します！大きな変更の場合は、まずissueを開いて変更内容を議論してください。

## 📄 ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照

## 🔗 関連リンク

- [MCP (Model Context Protocol)](https://modelcontextprotocol.io)
- [Google Cloud Run](https://cloud.google.com/run)
- [Google BigQuery](https://cloud.google.com/bigquery)
- [Claude Desktop](https://claude.ai/desktop)

## 🙏 謝辞

- Google Cloud Platform チーム（MCP Toolboxコンテナの提供）
- Anthropic チーム（MCP プロトコルの開発）