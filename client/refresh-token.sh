#!/bin/bash
# トークン自動更新用スクリプト

while true; do
  ./setup.sh
  echo "Token refreshed at $(date)"
  sleep 2700  # 45分ごとに更新
done