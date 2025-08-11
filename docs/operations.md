# 運用ガイド

## 日常運用

### ログ監視

#### Cloud Runログの確認
```bash
# 最新50件のログ
make logs

# リアルタイムログ監視
gcloud run logs tail mcp-toolbox-bigquery --region=asia-northeast1

# 特定期間のログ
gcloud logging read "resource.type=cloud_run_revision \
  AND resource.labels.service_name=mcp-toolbox-bigquery" \
  --limit=100 \
  --format=json
```

#### エラーログの検索
```bash
# エラーログのみ表示
gcloud logging read "resource.type=cloud_run_revision \
  AND resource.labels.service_name=mcp-toolbox-bigquery \
  AND severity>=ERROR" \
  --limit=50
```

### メトリクス監視

#### Cloud Runメトリクス
```bash
# CPU使用率の確認
gcloud monitoring metrics-descriptors list \
  --filter="metric.type:run.googleapis.com/container/cpu/utilizations"

# メモリ使用率の確認
gcloud monitoring metrics-descriptors list \
  --filter="metric.type:run.googleapis.com/container/memory/utilizations"
```

#### BigQueryメトリクス
```bash
# クエリ実行数
gcloud monitoring metrics-descriptors list \
  --filter="metric.type:bigquery.googleapis.com/query/count"

# データ処理量
gcloud monitoring metrics-descriptors list \
  --filter="metric.type:bigquery.googleapis.com/query/scanned_bytes"
```

### トークン管理

#### 手動トークン更新
```bash
cd client
./setup.sh
```

#### 自動トークン更新
```bash
# バックグラウンドで実行
nohup ./client/refresh-token.sh > refresh.log 2>&1 &

# プロセスの確認
ps aux | grep refresh-token

# プロセスの停止
kill $(ps aux | grep refresh-token | grep -v grep | awk '{print $2}')
```

### アプリケーション更新

#### サーバー側の更新
```bash
# 1. コード変更後
cd server
# tools.yamlやDockerfileを編集

# 2. デプロイ
make deploy

# 3. 動作確認
make logs
```

#### Terraform更新
```bash
# 1. 設定変更
vim terraform/terraform.tfvars

# 2. 変更確認
make plan

# 3. 適用
make apply
```

## メンテナンス

### 定期メンテナンス（月次）

1. **サービスアカウントキーのローテーション**
```bash
# 古いキーのリスト
gcloud iam service-accounts keys list \
  --iam-account=mcp-toolbox-client@PROJECT_ID.iam.gserviceaccount.com

# 新しいキーの作成
gcloud iam service-accounts keys create \
  ~/.config/mcp-toolbox/service-account-key-new.json \
  --iam-account=mcp-toolbox-client@PROJECT_ID.iam.gserviceaccount.com

# 古いキーの削除
gcloud iam service-accounts keys delete KEY_ID \
  --iam-account=mcp-toolbox-client@PROJECT_ID.iam.gserviceaccount.com
```

2. **コンテナイメージのクリーンアップ**
```bash
# 古いイメージの確認
gcloud artifacts docker images list \
  asia-northeast1-docker.pkg.dev/PROJECT_ID/mcp-toolbox

# 古いイメージの削除（最新10個を残す）
# Terraformで自動設定済み
```

3. **ログのアーカイブ**
```bash
# Cloud Loggingエクスポート設定
gcloud logging sinks create mcp-toolbox-archive \
  storage.googleapis.com/mcp-toolbox-logs-archive \
  --log-filter="resource.type=cloud_run_revision"
```

### セキュリティ監査（四半期）

1. **IAM権限の確認**
```bash
# プロジェクトレベルの権限
gcloud projects get-iam-policy PROJECT_ID

# サービスアカウントの権限
gcloud iam service-accounts get-iam-policy \
  mcp-toolbox-sa@PROJECT_ID.iam.gserviceaccount.com
```

2. **アクセスログの確認**
```bash
# Cloud Run呼び出しログ
gcloud logging read "protoPayload.serviceName=run.googleapis.com \
  AND protoPayload.resourceName:mcp-toolbox-bigquery" \
  --limit=100
```

3. **脆弱性スキャン**
```bash
# コンテナイメージのスキャン
gcloud artifacts docker images scan \
  asia-northeast1-docker.pkg.dev/PROJECT_ID/mcp-toolbox/mcp-toolbox-bigquery:latest
```

## パフォーマンスチューニング

### Cloud Run最適化

```bash
# 同時実行数の調整
gcloud run services update mcp-toolbox-bigquery \
  --concurrency=100 \
  --region=asia-northeast1

# CPUとメモリの調整
gcloud run services update mcp-toolbox-bigquery \
  --cpu=2 \
  --memory=2Gi \
  --region=asia-northeast1
```

### BigQuery最適化

1. **クエリ最適化**
   - パーティションテーブルの使用
   - クラスタリングの適用
   - マテリアライズドビューの作成

2. **コスト最適化**
   - スロット予約の検討
   - ストレージの定期クリーンアップ

## バックアップとリカバリ

### Terraformステートのバックアップ

```bash
# 手動バックアップ
gsutil cp -r gs://terraform-state-PROJECT_ID/mcp-toolbox \
  gs://backup-bucket/terraform-state-$(date +%Y%m%d)/
```

### 設定のバックアップ

```bash
# 設定ファイルのバックアップ
tar -czf mcp-toolbox-config-$(date +%Y%m%d).tar.gz \
  terraform/terraform.tfvars \
  server/tools.yaml \
  client/setup.sh
```

## アラート設定

### Cloud Monitoringアラート

```bash
# エラー率アラート
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="MCP Toolbox Error Rate" \
  --condition-display-name="High Error Rate" \
  --condition-threshold-value=0.01 \
  --condition-threshold-duration=300s
```

### 予算アラート

```bash
# 月額予算の設定
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="MCP Toolbox Budget" \
  --budget-amount=50USD \
  --threshold-rule=percent=80
```