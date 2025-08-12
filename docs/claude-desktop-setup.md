# Claude Desktop MCP設定ガイド

このガイドでは、Claude DesktopからCloud Run経由でBigQueryにアクセスするための設定方法を詳しく説明します。

## 📋 前提条件

- Claude Desktopがインストール済み
- npmがインストール済み（Node.js v16以上）

## 🔧 セットアップ手順

### 1. 必要な情報の確認

このMCPサーバーはパブリックアクセス可能なCloud Run上で動作しています。
特別な認証情報は必要ありません。

### 2. mcp-remoteについて

**インストール不要です！** 

設定ファイルで `npx -y` を使用するため、mcp-remoteは自動的にダウンロード・実行されます。

```bash
# 手動インストールは不要（npxが自動処理）
# 設定ファイルに既に含まれています: "npx -y mcp-remote ..."
```

**オプション：手動インストール**  
特定の環境（オフライン環境など）でのみ必要：
```bash
npm install -g mcp-remote
# この場合、設定ファイルの "npx -y" を "mcp-remote" に変更
```

### 3. Claude Desktop設定ファイルの場所

設定ファイルの場所：

**macOS:**
```bash
# ファイルパス
~/Library/Application Support/Claude/claude_desktop_config.json

# ディレクトリを開く
open ~/Library/Application\ Support/Claude/
```

**Windows:**
```powershell
# ファイルパス
%APPDATA%\Claude\claude_desktop_config.json

# ディレクトリを開く
explorer %APPDATA%\Claude
```

**Linux:**
```bash
~/.config/Claude/claude_desktop_config.json
```

### 4. 設定ファイルの編集

設定ファイルが存在しない場合は新規作成し、以下の内容を記載します：

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

⚠️ **注意**: 
- 認証情報は不要です
- Cloud Runサービスに直接アクセスします

### 5. Claude Desktopの再起動

設定を反映させるため、Claude Desktopを完全に終了してから再起動します：

**macOS:**
1. メニューバーのClaudeアイコンから「Quit Claude」を選択
2. アプリケーションフォルダからClaude Desktopを起動

**Windows:**
1. システムトレイのClaudeアイコンを右クリック→「終了」
2. スタートメニューからClaude Desktopを起動

## ✅ 動作確認

### 6. 接続状態の確認

Claude Desktopを起動後、以下の方法でMCPサーバーの接続を確認します：

1. **新しいチャットを開始**
2. **MCPツールアイコンを確認** - チャット入力欄の近くにツールアイコンが表示されているか
3. **「/」を入力** - 利用可能なコマンドが表示されるか確認



### 7. テストクエリの実行

以下のようなメッセージをClaudeに送信して動作を確認します：

```
BigQueryのデータセット一覧を表示してください
```

または

```
SELECT * FROM `your-dataset.your-table` LIMIT 10 を実行してください
```

## 📦 利用可能なMCPツール

| ツール名 | 説明 | 使用例 |
|---------|------|--------|
| `query` | SQLクエリを実行 | BigQueryでSQLを実行してください |
| `list-datasets` | データセット一覧を取得 | データセットをリストしてください |
| `list-tables` | テーブル一覧を取得 | dataset_nameのテーブルを表示して |
| `table-info` | テーブル情報を取得 | table_nameのスキーマを見せて |

## 🔐 セキュリティ

### アクセス制御

- Cloud Runサービスはパブリックアクセス可能
- BigQueryへの読み取り専用アクセス
- サービスアカウントで権限を制限

## 🚨 トラブルシューティング

### 接続エラーが発生する場合

1. **mcp-remoteがインストールされているか確認**
   ```bash
   npm list -g mcp-remote
   ```

2. **ネットワーク接続の確認**
   ```bash
   curl https://mcp-toolbox-2fbutm4xoa-an.a.run.app/health
   # "OK" が返ってくれば成功
   ```

### MCPサーバーが起動しない場合

1. Claude Desktopを完全に終了して再起動
2. 設定ファイルのJSON構文を確認
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