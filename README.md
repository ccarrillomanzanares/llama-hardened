# llama-hardened

Stack de inferencia LLM del VPS con **llama-server** (fork `MBZUAI-IFM/llama.cpp`
rama `model/K2Horizon`, commit `35999d1`) detrás de **Caddy** con autenticación
`X-API-Key`. Sirve modelos de la familia **K2-Horizon** (arquitectura MoVA) que
el Ollama actual aún no soporta.

- Endpoint público: `https://webuillama.ccmai.org/v1/chat/completions` (Cloudflare → Caddy `:8443`)
- Auth: header `X-API-Key` (misma clave que ollama-hardened, en `.env`)
- Modelo por defecto: `K2-Horizon-7B-Q4_K_M.gguf` (5.6 GB, Q4_K_M)
- Imagen: compilada del fork (binarios en `bin/`, libs en `lib/`), servida desde el contenedor `llama-core`

## Requisitos

- Docker + docker compose plugin en el VPS
- Modelo GGUF en `models/` (copiado de `~/k2-test/` o `~/models/`)
- `.env` con `OLLAMA_API_KEY`, `DOMAIN`, `EMAIL_ADMIN` (igual que ollama-hardened)
- **Binarios `bin/` y `lib/` compilados del fork** (no se versionan: dependen de la
  glibc del host). Obtenerlos así en el VPS:

```bash
# 1. Compilar el fork una vez (o copiar de un build existente)
git clone --depth 1 --branch model/K2Horizon https://github.com/MBZUAI-IFM/llama.cpp.git llama-k2
cd llama-k2
cmake -B build -DCMAKE_BUILD_TYPE=Release -DGGML_NATIVE=OFF
cmake --build build --target llama-server llama-cli -j $(nproc)

# 2. Copiar binarios + libs al stack
mkdir -p ~/llama-hardened/{bin,lib}
cp build/bin/llama-server build/bin/llama-cli ~/llama-hardened/bin/
cp build/bin/libllama*.so* build/bin/libggml*.so* build/bin/libmtmd*.so* ~/llama-hardened/lib/
```

## Modelos y rutas

| Modelo | Contenedor | Ruta pública |
|---|---|---|
| K2-Horizon-7B Q4_K_M (5.6G) | `llama-core` | `/v1/*` |
| Qwen3.5-9B Q4_K_M (6.2G) | `llama-qwen` | `/ollama/*` |

Ambos comparten la misma `X-API-Key`. Copiar los modelos así:

```bash
cp ~/k2-test/K2-Horizon-7B-Q4_K_M.gguf ~/llama-hardened/models/
cp ~/models/Qwen_Qwen3.5-9B-Q4_K_M.gguf  ~/llama-hardened/models/
```

## Uso

```bash
./setup.sh          # build + up + verificación
sudo docker compose logs -f llama    # logs del servidor
sudo docker compose down             # parar
```

Verificación real (desde fuera, por Cloudflare):

```bash
KEY=$(grep "^OLLAMA_API_KEY=" .env | cut -d= -f2)
curl -sS -H "X-API-Key: $KEY" \
  -d '{"messages":[{"role":"user","content":"di ok"}],"max_tokens":50}' \
  https://webuillama.ccmai.org/v1/chat/completions
```

## Nota

Cuando el soporte K2 llegue al llama.cpp mainline y a Ollama, este stack podrá
migrarse a un `ollama create` y retirar el servicio `llama` (ver `k2-llama-mainline-watch`).
