#!/bin/sh
# llama-server hardened entrypoint - serve Qwen3.5-9B (alternative model)
set -e
export LD_LIBRARY_PATH=/usr/local/lib
exec /usr/local/bin/llama-server \
  -m /models/Qwen_Qwen3.5-9B-Q4_K_M.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --jinja \
  -c 32768 \
  -t 14
