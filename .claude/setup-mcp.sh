#!/bin/bash

# MCP Toolbox Remote Server Setup Script for Claude Code
# This script generates an access token and updates the MCP configuration

set -e

echo "Setting up MCP Toolbox remote server for Claude Code..."

# Generate access token
TOKEN=$(gcloud auth print-identity-token)

if [ -z "$TOKEN" ]; then
    echo "Error: Failed to generate access token. Please run 'gcloud auth login' first."
    exit 1
fi

# Create MCP configuration
cat > .claude/mcp.json << EOF
{
  "mcpServers": {
    "mcp-toolbox-bigquery": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-remote",
        "https://mcp-toolbox-2fbutm4xoa-an.a.run.app/mcp"
      ],
      "env": {
        "MCP_REMOTE_HEADERS": "{\\"Authorization\\":\\"Bearer ${TOKEN}\\"}"
      }
    }
  }
}
EOF

echo "✅ MCP configuration updated successfully!"
echo "📝 Configuration saved to: .claude/mcp.json"
echo "⏱️  Token expires in 1 hour. Run this script again to refresh."
echo ""
echo "🔄 To use in Claude Code:"
echo "   1. Restart Claude Code or reload the window"
echo "   2. The MCP server will be available automatically"