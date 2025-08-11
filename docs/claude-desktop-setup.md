# Claude Desktop MCP設定ガイド

このガイドでは、Claude DesktopからGoogle Cloud Run上のMCP Toolboxサーバーに接続する方法を説明します。

## 📋 前提条件

- Claude Desktopがインストール済み
- npmがインストール済み
- Google Cloud Runサービスがデプロイ済み
- サービスアカウントキーファイルを取得済み

## 🔧 セットアップ手順

### 1. mcp-remoteのインストール

```bash
npm install -g @modelcontextprotocol/mcp-remote
```

### 2. サービスアカウントキーの取得と配置

#### 管理者がキーを生成する場合：
```bash
# サービスアカウントキーを生成（管理者のみ実行）
gcloud iam service-accounts keys create mcp-toolbox-key.json \
  --iam-account=mcp-toolbox-sa@trans-grid-245207.iam.gserviceaccount.com
```

#### ユーザーがキーを配置する手順：

1. **キーファイルを受け取る**
   - 管理者から `mcp-toolbox-key.json` または類似のファイルを受け取ります

2. **保存用ディレクトリを作成してキーを配置**
   ```bash
   # ディレクトリ作成
   mkdir -p ~/.mcp
   
   # キーファイルをコピー（ダウンロードフォルダから配置する例）
   cp ~/Downloads/mcp-toolbox-key.json ~/.mcp/bigquery-key.json
   
   # 権限を設定（重要！）
   chmod 600 ~/.mcp/bigquery-key.json
   ```

3. **配置先の確認**
   ```bash
   # ファイルが正しく配置されたか確認
   ls -la ~/.mcp/bigquery-key.json
   ```

実際の保存場所：
- **macOS/Linux**: `/Users/あなたのユーザー名/.mcp/bigquery-key.json`
- **Windows**: `C:\Users\あなたのユーザー名\.mcp\bigquery-key.json`

⚠️ **重要**: このファイルは機密情報です。安全に管理してください。

### 3. Claude Desktop設定ファイルの編集

Claude Desktopの設定ファイルを開きます：

**macOS:**
```bash
~/Library/Application Support/Claude/claude_desktop_config.json
```

**Windows:**
```
%APPDATA%\Claude\claude_desktop_config.json
```

### 4. MCP設定の追加

以下の設定を`claude_desktop_config.json`に追加します：

```json
{
  "mcpServers": {
    "mcp-toolbox-bigquery": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/mcp-remote",
        "https://mcp-toolbox-2fbutm4xoa-an.a.run.app"
      ],
      "env": {
        "GOOGLE_APPLICATION_CREDENTIALS": "/Users/あなたのユーザー名/.mcp/bigquery-key.json"
      }
    }
  }
}
```

⚠️ **重要な注意事項**: 
- **macOS/Linux**: `/Users/あなたのユーザー名` を実際のユーザー名に置き換えてください
  - 例: `/Users/tsutomutomizawa/.mcp/bigquery-key.json`
- **Windows**: `C:\Users\あなたのユーザー名\.mcp\bigquery-key.json` を使用
  - 例: `C:\Users\tsutomutomizawa\.mcp\bigquery-key.json`
- **フルパスで記載する必要があります**（`~`は使用できません）

### 5. Claude Desktopの再起動

設定を反映させるため、Claude Desktopを再起動します。

## ✅ 動作確認

### 設定ファイルの実際の例

例えば、ユーザー名が `tsutomutomizawa` の場合：

**macOS用の完全な設定例：**
```json
{
  "mcpServers": {
    "mcp-toolbox-bigquery": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/mcp-remote",
        "https://mcp-toolbox-2fbutm4xoa-an.a.run.app"
      ],
      "env": {
        "GOOGLE_APPLICATION_CREDENTIALS": "/Users/tsutomutomizawa/.mcp/bigquery-key.json"
      }
    }
  }
}
```

### 接続テスト

Claude Desktopで以下のようなメッセージを送信して動作を確認します：

```
BigQueryのmeta_1900film2データセットにあるテーブルを一覧表示してください
```

正常に動作すれば、以下のようなツールが利用可能になります：
- `query` - SQLクエリの実行
- `list-datasets` - データセット一覧
- `list-tables` - テーブル一覧
- `table-info` - テーブル情報取得

## 🔐 セキュリティ

### サービスアカウントキーの管理

1. **アクセス制限**: キーファイルは必要最小限のユーザーのみがアクセスできるようにする
2. **権限設定**: ファイルのパーミッションを適切に設定
   ```bash
   chmod 600 ~/.mcp/bigquery-key.json
   ```
3. **定期ローテーション**: 3ヶ月ごとにキーを更新することを推奨
4. **Git管理除外**: 絶対にGitリポジトリにコミットしない

### 権限の範囲

このサービスアカウントには以下の権限があります：
- BigQueryデータの読み取り（`roles/bigquery.dataViewer`）
- BigQueryジョブの実行（`roles/bigquery.user`）
- Cloud Runサービスの呼び出し（`roles/run.invoker`）

## 🚨 トラブルシューティング

### 接続エラーが発生する場合

1. **キーファイルのパスを確認**
   ```bash
   # ファイルが存在するか確認
   ls -la ~/.mcp/bigquery-key.json
   
   # 実際のフルパスを表示
   echo /Users/$(whoami)/.mcp/bigquery-key.json
   ```

2. **Claude Desktop設定のパスが正しいか確認**
   - 設定ファイルのパスがフルパスで記載されているか
   - ユーザー名が正しく置き換えられているか

3. **ネットワーク接続の確認**
   ```bash
   curl https://mcp-toolbox-2fbutm4xoa-an.a.run.app/health
   ```

### 認証エラーが発生する場合

1. キーファイルの有効性を確認
2. サービスアカウントの権限を確認
3. Cloud Runサービスのステータスを確認

### ログの確認

問題が解決しない場合は、Claude Desktopのログを確認：
- macOS: `~/Library/Logs/Claude/`
- Windows: `%LOCALAPPDATA%\Claude\logs\`

## 📚 関連ドキュメント

- [MCP (Model Context Protocol) 公式ドキュメント](https://modelcontextprotocol.io)
- [Google Cloud Run ドキュメント](https://cloud.google.com/run/docs)
- [BigQuery ドキュメント](https://cloud.google.com/bigquery/docs)

## 💬 サポート

問題が発生した場合は、プロジェクト管理者に連絡してください。