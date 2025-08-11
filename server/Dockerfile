# Google公式のMCP Toolboxイメージを使用
FROM us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:0.11.0

# 設定ファイルをコピー
COPY tools.yaml /app/tools.yaml

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1

# ポート公開
EXPOSE 8080

# MCP Toolbox起動（カスタム設定を使用）
ENTRYPOINT ["/toolbox"]
CMD ["--tools-file", "/app/tools.yaml", "--port", "8080", "--address", "0.0.0.0", "--log-level", "INFO"]