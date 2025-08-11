#!/bin/bash
# MCPプロトコルテストクライアント

set -e

# テスト用のMCPリクエスト送信
echo "Testing MCP Protocol..."

# 1. Initialize
echo "1. Testing initialize..."
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "initialize",
    "params": {
      "protocolVersion": "0.1.0",
      "capabilities": {
        "tools": {}
      },
      "clientInfo": {
        "name": "test-client",
        "version": "1.0.0"
      }
    },
    "id": 1
  }' | jq .

echo ""

# 2. List tools
echo "2. Testing tools/list..."
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "params": {},
    "id": 2
  }' | jq .

echo ""

# 3. Call a tool (list datasets)
echo "3. Testing tools/call (list-datasets)..."
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "list-datasets",
      "arguments": {}
    },
    "id": 3
  }' | jq .

echo ""
echo "✅ MCP Protocol tests completed!"