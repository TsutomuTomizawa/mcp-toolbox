# トラブルシューティングガイド

## よくある問題と解決方法

### 1. Claude Desktopで🔨アイコンが表示されない

**症状**: Claude Desktop起動後、入力欄にMCPツールアイコンが表示されない

**原因と解決方法**:

1. **設定ファイルの確認**
```bash
# 設定ファイルの場所を確認
ls -la "$HOME/Library/Application Support/Claude/claude_desktop_config.json"

# 設定内容を確認
cat "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
```

2. **Claude Desktopの完全再起動**
```bash
# macOS
killall Claude
# アプリケーションを再度起動

# Windows
# タスクマネージャーからClaude関連プロセスを終了
```

3. **設定の再生成**
```bash
cd client
./setup.sh
```

### 2. "401 Unauthorized" エラー

**症状**: MCPツール使用時に認証エラーが発生

**原因と解決方法**:

1. **トークンの期限切れ**
```bash
# 新しいトークンを取得
cd client
./setup.sh
```

2. **サービスアカウントキーの確認**
```bash
# キーファイルの存在確認
ls -la ~/.config/mcp-toolbox/service-account-key.json

# キーの再作成が必要な場合
gcloud iam service-accounts keys create \
  ~/.config/mcp-toolbox/service-account-key.json \
  --iam-account=$(cd terraform && terraform output -raw client_sa_email)
```

3. **IAM権限の確認**
```bash
# Cloud Run Invoker権限の確認
gcloud run services get-iam-policy mcp-toolbox-bigquery \
  --region=asia-northeast1
```

### 3. "Service Unavailable" エラー

**症状**: Cloud Runサービスが応答しない

**原因と解決方法**:

1. **サービスの状態確認**
```bash
# サービスの詳細表示
gcloud run services describe mcp-toolbox-bigquery \
  --region=asia-northeast1

# ステータスがReadyでない場合は、ログを確認
make logs
```

2. **コンテナイメージの確認**
```bash
# 最新イメージの確認
gcloud artifacts docker images list \
  asia-northeast1-docker.pkg.dev/$(gcloud config get-value project)/mcp-toolbox

# イメージの再ビルド・デプロイ
make deploy
```

3. **リソース制限の確認**
```bash
# CPU/メモリ不足の場合
gcloud run services update mcp-toolbox-bigquery \
  --cpu=2 \
  --memory=2Gi \
  --region=asia-northeast1
```

### 4. BigQueryエラー

#### "Permission denied" エラー

**原因と解決方法**:

```bash
# サービスアカウントの権限確認
gcloud projects get-iam-policy $(gcloud config get-value project) \
  --flatten="bindings[].members" \
  --filter="bindings.members:mcp-toolbox-sa"

# 必要な権限の付与
gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
  --member="serviceAccount:mcp-toolbox-sa@$(gcloud config get-value project).iam.gserviceaccount.com" \
  --role="roles/bigquery.dataViewer"
```

#### "Dataset not found" エラー

**原因と解決方法**:

```bash
# データセットの一覧確認
bq ls

# データセットが存在しない場合は作成
bq mk --dataset --location=asia-northeast1 your_dataset_name
```

### 5. Terraform関連のエラー

#### "Backend initialization required" エラー

```bash
# バックエンドの初期化
cd terraform
terraform init -reconfigure
```

#### "Resource already exists" エラー

```bash
# 既存リソースのインポート
terraform import google_service_account.mcp_toolbox \
  projects/PROJECT_ID/serviceAccounts/mcp-toolbox-sa@PROJECT_ID.iam.gserviceaccount.com

# または、既存リソースの削除後に再作成
terraform destroy -target=RESOURCE_NAME
terraform apply
```

### 6. GitHub Actions失敗

#### Workload Identity認証エラー

**原因と解決方法**:

1. **GitHub Secretsの確認**
   - `GCP_PROJECT_ID`
   - `WIF_PROVIDER`
   - `WIF_SERVICE_ACCOUNT`

2. **Workload Identity設定の確認**
```bash
# プロバイダーの確認
gcloud iam workload-identity-pools providers describe github-provider \
  --workload-identity-pool=github-pool \
  --location=global

# 属性条件の確認（リポジトリ名が正しいか）
```

### 7. ネットワーク関連の問題

#### タイムアウトエラー

**原因と解決方法**:

1. **リージョンの確認**
```bash
# Cloud Runサービスのリージョン
gcloud run services list --format="value(metadata.name,region)"
```

2. **ファイアウォール/プロキシ設定**
   - 企業ネットワーク内の場合、プロキシ設定が必要な場合があります
   - Cloud Runは完全にパブリックアクセス可能である必要があります

### デバッグ用コマンド集

```bash
# 全体的な状態確認
echo "=== Cloud Run Status ==="
gcloud run services describe mcp-toolbox-bigquery --region=asia-northeast1 --format=json | jq '.status'

echo "=== Recent Logs ==="
gcloud run logs read mcp-toolbox-bigquery --region=asia-northeast1 --limit=20

echo "=== IAM Policies ==="
gcloud run services get-iam-policy mcp-toolbox-bigquery --region=asia-northeast1

echo "=== Service Account Keys ==="
gcloud iam service-accounts keys list \
  --iam-account=mcp-toolbox-client@$(gcloud config get-value project).iam.gserviceaccount.com

echo "=== BigQuery Datasets ==="
bq ls

echo "=== Current Token Status ==="
gcloud auth application-default print-access-token >/dev/null 2>&1 && echo "Token valid" || echo "Token invalid"
```

## サポート

上記で解決しない場合は、以下の情報を含めてIssueを作成してください：

1. エラーメッセージの全文
2. 実行したコマンド
3. `make logs`の出力
4. プロジェクトID（機密情報は除く）
5. 使用しているOS