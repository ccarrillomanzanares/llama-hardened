#!/bin/sh
# llama-server hardened entrypoint - serve Nemotron-3.5-Lightning (MoE 30B/3B)
set -e
export LD_LIBRARY_PATH=/usr/local/lib
exec /usr/local/bin/llama-server \
  -m /models/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-Q4_K_M.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --jinja \
  --reasoning-budget 512 \
  -c 32768 \
  -t 14
