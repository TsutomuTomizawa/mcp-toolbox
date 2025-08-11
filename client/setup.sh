#!/bin/bash
set -e

# 設定
PROJECT_ID="${1:-$(gcloud config get-value project)}"
KEY_DIR="${HOME}/.config/mcp-toolbox"
KEY_FILE="${KEY_DIR}/service-account-key.json"

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}MCP Toolbox Client Setup${NC}"
echo "========================="

# 1. サービスアカウントキー作成（初回のみ）
if [ ! -f "$KEY_FILE" ]; then
  echo -e "${BLUE}Creating service account key...${NC}"
  
  mkdir -p "$KEY_DIR"
  
  # Terraformから情報取得
  cd terraform
  CLIENT_SA=$(terraform output -raw client_sa_email)
  cd ..
  
  # キー作成
  gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$CLIENT_SA" \
    --project="$PROJECT_ID"
  
  chmod 600 "$KEY_FILE"
  echo -e "${GREEN}✓ Service account key created${NC}"
else
  echo -e "${GREEN}✓ Using existing service account key${NC}"
fi

# 2. Cloud Run URLを取得
echo -e "${BLUE}Getting Cloud Run service URL...${NC}"
SERVICE_URL=$(gcloud run services describe mcp-toolbox-bigquery \
  --region=asia-northeast1 \
  --format='value(status.url)' \
  --project="$PROJECT_ID")

echo -e "${GREEN}✓ Service URL: $SERVICE_URL${NC}"

# 3. アクセストークン取得
echo -e "${BLUE}Getting access token...${NC}"
ACCESS_TOKEN=$(gcloud auth application-default print-access-token \
  --impersonate-service-account=$(jq -r .client_email < "$KEY_FILE"))

# 4. Claude Desktop設定
echo -e "${BLUE}Updating Claude Desktop configuration...${NC}"

# OS別の設定パス
case "$(uname)" in
  Darwin)
    CONFIG_DIR="$HOME/Library/Application Support/Claude"
    ;;
  Linux)
    CONFIG_DIR="$HOME/.config/Claude"
    ;;
  *)
    CONFIG_DIR="$APPDATA/Claude"
    ;;
esac

CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
mkdir -p "$CONFIG_DIR"

# 設定ファイル生成
cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
    "bigquery": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "${SERVICE_URL}/mcp",
        "--header",
        "Authorization: Bearer ${ACCESS_TOKEN}"
      ]
    }
  }
}
EOF

echo -e "${GREEN}✓ Configuration updated${NC}"

# 5. 完了メッセージ
echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Restart Claude Desktop"
echo "2. Look for the 🔨 icon in the input field"
echo "3. Try asking: 'What datasets are available?'"
echo ""
echo -e "${BLUE}Note: Token expires in 1 hour${NC}"
echo "Run this script again to refresh: ./client/setup.sh"