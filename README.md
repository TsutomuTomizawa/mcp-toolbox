# MCP Toolbox BigQuery

LLM（Claude Desktop等）からBigQueryに自然言語でアクセスできるMCPサーバー実装。

**デプロイ済みサービス**: https://mcp-toolbox-2fbutm4xoa-an.a.run.app

## 特徴

- ✅ **MCP Toolbox**: Google公式のエンタープライズグレード実装
- ✅ **Cloud Run**: サーバーレスで自動スケーリング
- ✅ **Terraform**: Infrastructure as Codeで管理
- ✅ **GitHub Actions**: CI/CDパイプライン

## クイックスタート

### 前提条件

- Google Cloud アカウント
- gcloud CLI
- Terraform
- Docker
- Claude Desktop

### セットアップ

1. **環境変数の設定**
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# ファイルを編集して実際の値を設定
```

2. **インフラストラクチャの構築**
```bash
make init
make apply
```

3. **アプリケーションのデプロイ**
```bash
make deploy
```

## ローカルテスト

```bash
# ビルドと起動
make local-build
make local-start

# テスト実行
make local-test

# 停止
make local-stop
```

## 使い方

### Claude Codeでの利用

リポジトリ内でMCPサーバーを使用：

```bash
# 初回セットアップ（認証トークン生成）
./.claude/setup-mcp.sh

# Claude Codeを再起動すると、MCPツールが利用可能になります
```

**注意**: トークンは1時間で期限切れになるため、定期的に`setup-mcp.sh`を実行してください。

### 利用可能なツール

- `execute_sql`: SQLクエリ実行
- `list_dataset_ids`: データセット一覧
- `list_table_ids`: テーブル一覧  
- `get_table_info`: テーブル情報取得
- `get_dataset_info`: データセット情報取得

## アーキテクチャ

```
Claude Desktop → mcp-remote → Cloud Run → BigQuery
```

## コマンド一覧

```bash
make help     # ヘルプ表示
make init     # Terraform初期化
make apply    # インフラ構築
make deploy   # アプリデプロイ
make logs     # ログ表示
```

## トラブルシューティング

### 接続エラー
```bash
make logs  # Cloud Runのログを確認
```


## ライセンス

MIT# Test deployment trigger - Tue Aug 12 01:18:29 JST 2025
