#!/usr/bin/env bash
# Build and start llama-hardened stack (llama-server fork + Caddy X-API-Key)
set -euo pipefail
cd "$(dirname "$0")"

echo "==> Construyendo imagen llama-core (fork K2 build 35999d1)..."
sudo docker compose build llama

echo "==> Levantando stack..."
sudo docker compose up -d

echo "==> Esperando a que llama-core escuche..."
for i in $(seq 1 30); do
  if sudo docker exec llama-core sh -c "curl -s -m 2 http://127.0.0.1:8080/health" >/dev/null 2>&1; then
    echo "OK: llama-core listo."
    break
  fi
  sleep 2
done

echo "==> Verificación local (con --resolve para forzar hostname):"
KEY=$(grep "^OLLAMA_API_KEY=" .env | cut -d= -f2)
R="--resolve ${DOMAIN:-webuillama.ccmai.org}:8443:127.0.0.1"
curl -sk $R "https://${DOMAIN:-webuillama.ccmai.org}:8443/health" && echo " (health OK)"
curl -sk $R -o /dev/null -w "sin key → %{http_code}\n" "https://${DOMAIN:-webuillama.ccmai.org}:8443/v1/models" || true
curl -sk $R -o /dev/null -w "con key → %{http_code}\n" -H "X-API-Key: $KEY" "https://${DOMAIN:-webuillama.ccmai.org}:8443/v1/models" || true
