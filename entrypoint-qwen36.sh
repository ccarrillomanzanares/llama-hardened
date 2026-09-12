#!/bin/sh
# llama-server hardened entrypoint - serve Qwen3.6-35B-A3B (MoE, agentico, multimodal)
set -e
export LD_LIBRARY_PATH=/usr/local/lib
exec /usr/local/bin/llama-server \
  -m /models/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf \
  --mmproj /models/mmproj-qwen3.6-F16.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --jinja \
  -c 32768 \
  -t 14 \
  `# Anti-degeneration (13 Sep 2026): the defaults had repetition penalties OFF` \
  `# (repeat-penalty 1.00, dry 0.00) and the model could fall into a loop --` \
  `# an agentic tool call degenerated into a run of repeated "grep -v" pipes,` \
  `# producing invalid tool-call JSON, which llama-server answered with HTTP 500.` \
  --repeat-penalty 1.1 \
  --repeat-last-n 256 \
  --dry-multiplier 0.8 \
  --dry-base 1.75 \
  --dry-allowed-length 2 \
  --top-p 0.9 \
  --top-k 40 \
  --min-p 0.05
