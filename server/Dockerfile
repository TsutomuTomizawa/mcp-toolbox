# マルチステージビルド

# Stage 1: プロキシサーバーのビルド
FROM golang:1.21-alpine AS proxy-builder
WORKDIR /build
COPY proxy/main.go .
RUN go mod init proxy && go build -o api-proxy main.go

# Stage 2: 最終イメージ
FROM us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:0.11.0

# プロキシとスーパーバイザーのインストール
RUN apt-get update && apt-get install -y supervisor && rm -rf /var/lib/apt/lists/*

# プロキシバイナリをコピー
COPY --from=proxy-builder /build/api-proxy /usr/local/bin/api-proxy

# 設定ファイルをコピー
COPY tools.yaml /app/tools.yaml

# Supervisord設定
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1

# ポート公開
EXPOSE 8080

# Supervisord起動（プロキシとMCP Toolboxを同時起動）
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]