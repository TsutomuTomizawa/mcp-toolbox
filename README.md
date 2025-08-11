# MCP Toolbox for BigQuery

Google Cloud上でBigQueryアクセスを提供するMCP (Model Context Protocol) サーバーの実装。  
Claude DesktopからAPI Gateway経由でセキュアにBigQueryを操作できます。

## 🏗️ アーキテクチャ

```
Claude Desktop → Cloud Run (MCP Toolbox) → BigQuery
```

### コンポーネント

- **Cloud Run**: MCP Toolboxサーバー（Google公式コンテナ）
- **BigQuery**: データウェアハウス
- **Terraform**: インフラストラクチャ管理

## 🚀 機能

- ✅ BigQueryへの読み取り専用アクセス
- ✅ SQLクエリ実行、テーブル/データセット一覧取得
- ✅ サーバーレスで自動スケーリング
- ✅ Claude Desktopとの完全統合

## 📁 プロジェクト構造

```
.
├── api-gateway/      # API Gateway設定
│   └── openapi-spec.yaml
├── docs/            # ドキュメント
│   ├── claude-desktop-setup.md
│   ├── deployment-guide.md
│   └── system-architecture.md
├── server/          # MCP Toolboxサーバー
│   ├── Dockerfile
│   └── tools.yaml
├── terraform/       # インフラストラクチャ定義
│   ├── main.tf
│   └── api-gateway.tf
└── .github/         # CI/CDワークフロー
    └── workflows/
```

## 🔧 セットアップ

### 前提条件

- Google Cloud アカウント
- gcloud CLI インストール済み
- Terraform インストール済み
- npm インストール済み（Claude Desktop用）

### 1. 初期設定

```bash
# リポジトリをクローン
git clone https://github.com/1900film/mcp-toolbox.git
cd mcp-toolbox

# Google Cloud認証
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Terraform変数を設定
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# terraform.tfvarsを編集
```

### 2. インフラストラクチャのデプロイ

```bash
# Terraform初期化
make init

# デプロイ計画を確認
make plan

# インフラをデプロイ
make apply
```

### 3. アプリケーションのデプロイ

```bash
# Cloud Runへデプロイ
make deploy
```

### 4. Claude Desktop設定

詳細は [Claude Desktop設定ガイド](docs/claude-desktop-setup.md) を参照。

簡単な設定例：

```json
{
  "mcpServers": {
    "mcp-toolbox-bigquery": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://mcp-toolbox-2fbutm4xoa-an.a.run.app/mcp"
      ]
    }
  }
}
```

## 📝 利用可能なMCPツール

| ツール名 | 説明 |
|---------|------|
| `query` | SQLクエリを実行 |
| `list-datasets` | データセット一覧を取得 |
| `list-tables` | テーブル一覧を取得 |
| `table-info` | テーブルメタデータを取得 |

## 🛠️ 開発・運用コマンド

```bash
# ヘルプを表示
make help

# インフラ管理
make init          # Terraformを初期化
make plan          # 実行計画を表示
make apply         # インフラをデプロイ
make destroy       # インフラを削除

# アプリケーション管理
make deploy        # Cloud Runへデプロイ
make logs          # ログを表示

# ローカル開発
make local-build   # Dockerイメージをビルド
make local-start   # ローカルで起動
make local-test    # テストを実行
make local-stop    # 停止
```

## 🔐 セキュリティ

### アクセス制御

1. Cloud Runサービスはパブリックアクセス可能
2. サービスアカウント経由でBigQueryにアクセス
3. BigQueryは読み取り専用権限のみ

### セキュリティ機能

- ✅ BigQuery読み取り専用権限
- ✅ 最小権限の原則
- ✅ サービスアカウントによるアクセス制御

## ⚙️ 環境変数・設定

### 必須の環境変数

| 変数名 | 説明 | デフォルト |
|--------|------|-----------|
| `PROJECT_ID` | GCPプロジェクトID | - |
| `REGION` | デプロイリージョン | asia-northeast1 |

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
gcloud run services describe mcp-toolbox --region=asia-northeast1
```

## 🤝 コントリビューション

1. このリポジトリをフォーク
2. 機能ブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチをプッシュ (`git push origin feature/amazing-feature`)
5. Pull Requestを作成

## 📄 ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照

## 🔗 関連リンク

- [MCP (Model Context Protocol)](https://modelcontextprotocol.io)
- [Google Cloud Run](https://cloud.google.com/run)
- [Google BigQuery](https://cloud.google.com/bigquery)
- [Claude Desktop](https://claude.ai/desktop)