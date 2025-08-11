# CLAUDE.md

このファイルはClaude Codeがこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要

BigQuery用のMCP (Model Context Protocol) Toolbox実装。LLMが自然言語でBigQueryとやり取りできるようにします。Google公式のMCP ToolboxコンテナをGoogle Cloud Runにデプロイして使用。

## 必須コマンド

### ローカル開発
```bash
# 認証設定（必須）
gcloud auth application-default login

# Docker操作
make local-build    # Dockerイメージをビルド
make local-start    # コンテナを起動
make local-test     # APIテストを実行
make local-stop     # コンテナを停止
```

### 本番デプロイ
```bash
# インフラストラクチャ
make init        # Terraformを初期化
make apply       # インフラを作成/更新

# アプリケーション
make deploy      # Cloud Runへデプロイ
make logs        # Cloud Runのログを表示
```

## アーキテクチャ

```
Claude Desktop → mcp-remote → Cloud Run (MCP Toolbox) → BigQuery
```

### 主要コンポーネント

1. **MCPサーバー** (`server/`)
   - コンテナ: `us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:0.11.0`
   - 設定: `tools.yaml`
   - ポート: 8080

2. **インフラストラクチャ** (`terraform/`)
   - Cloud Runサービス
   - サービスアカウント
   - Artifact Registry

## 設定

- **プロジェクトID**: trans-grid-245207
- **リージョン**: asia-northeast1
- **認証**: Application Default Credentials

## 利用可能なMCPツール

- `query`: SQLクエリを実行
- `list-datasets`: すべてのデータセットを一覧表示
- `list-tables`: データセット内のテーブルを一覧表示
- `table-info`: テーブルメタデータを取得

## テスト

ローカルテストエンドポイント: `http://localhost:8080`
- ヘルスチェック: `/health`
- MCP: `/mcp` (POSTでJSON-RPC)