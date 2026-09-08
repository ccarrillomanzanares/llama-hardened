#!/bin/sh
# llama-server hardened entrypoint - serve K2-Horizon with function calling
set -e
export LD_LIBRARY_PATH=/usr/local/lib
exec /usr/local/bin/llama-server \
  -m /models/K2-Horizon-7B-Q4_K_M.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --jinja \
  -c 32768 \
  -t 14
