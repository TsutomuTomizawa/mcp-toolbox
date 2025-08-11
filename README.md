# MCP Toolbox BigQuery

LLM（Claude Desktop等）からBigQueryに自然言語でアクセスできるMCPサーバー実装。

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

Claude Desktopを再起動後、🔨アイコンから以下のツールが利用可能：
- `query`: SQLクエリ実行
- `list-datasets`: データセット一覧
- `list-tables`: テーブル一覧
- `table-info`: テーブル情報取得

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
