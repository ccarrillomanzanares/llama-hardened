# Pendientes — llama-hardened

**Actualizado:** 2026-09-25
**Estado:** stack verificado en producción. `llama-qwen` sirviendo Qwen3.6-35B-A3B (Q4_K_M),
38 h arriba, 0 reinicios, detrás de Caddy con `X-API-Key`. Sin incidencias abiertas.

## Contexto (estado real, verificado el 2026-09-25)

### Qué corre de verdad

| Elemento | Detalle |
|---|---|
| `llama-qwen` | `Qwen3.6-35B-A3B-UD-Q4_K_M.gguf` (22,13 GB) + `mmproj-qwen3.6-F16.gguf` (858 MB, visión) |
| | `-c 32768 -t 14 --jinja`, sampling anti-degeneración (repeat-penalty 1.1, DRY 0.8) |
| | puerto 8080 **no publicado** al host: sólo se sale por el proxy |
| `llama-proxy` | Caddy, host `8443` -> `443`, TLS interno, auth `X-API-Key` |
| Reinicio | `restart: always` en ambos + `docker` `enabled` -> sobrevive a un reinicio del VPS |

### Rendimiento medido (generaciones de 400 tokens, no ráfagas)

| Medición | Decode | Prefill |
|---|---|---|
| 1ª pasada (caché fría) | 5,52 t/s | 12,8 t/s |
| 2ª pasada (caliente) | **10,91 t/s** | 26,6 t/s |

**Usar ~11 t/s para planificar.** Las ráfagas cortas dan ~18 t/s y engañan: a esa longitud el
tiempo lo domina el arranque, no el decode. `fincore` confirma el modelo al 99,95% residente
(22.123.651.072 de 22.134.528.992 bytes), así que **no pagina a disco**. La varianza viene de que
la caché de páginas compite con el resto de la maquina (`docker`, `apache`, `ollama`).

### Rutas del proxy

| Ruta | Upstream | Consumidor |
|---|---|---|
| `/v1/*` | `qwen:8080` | endpoint documentado |
| `/ollama/*` | `qwen:8080` (mismo modelo) | **aios-agent** y las ISOs ya distribuidas |
| `/health` | responde Caddy | monitorización |
| `/shell/*` | — | RETIRADA 2026-09-25: apuntaba a `llama-shell`, contenedor inexistente |
| `/base/*` | — | RETIRADA 2026-09-25 (sólo existía en un backup) |

## Pendiente

### 1. `--no-mmap` en `entrypoint-qwen36.sh` — el único cambio recomendado

**Por qué:** hoy los pesos van por `mmap` y viven en la caché de páginas, que es de todos.
Cualquier actividad en el VPS los desplaza y la siguiente generación arranca a ~5,5 t/s en vez de
~11. Con `--no-mmap` los pesos pasan a memoria anónima y, como el VPS **no tiene swap**, no los
puede echar nadie. Coste: cero pérdida de calidad. Contrapartida: el arranque lee los 22 GB de
disco (más lento al levantar, irrelevante después).

**Ojo:** cambiar el entrypoint exige **reconstruir la imagen** (va `COPY` dentro del Dockerfile) y
reiniciar el contenedor -> varios minutos sin endpoint mientras carga.

### 2. Probar decodificación especulativa MTP — ganar velocidad sin perder calidad

El binario (`build 10655`) soporta `--spec-type` con `draft-mtp`. Bartowski publica una cabeza MTP
**para este modelo exacto**:

```
bartowski/Qwen_Qwen3.6-35B-A3B-GGUF -> mtp-Qwen_Qwen3.6-35B-A3B-Q4_0.gguf   (1,19 GB)
```

En teoría recuperaría buena parte de la velocidad. **No verificado en este build** — experimento
barato, no promesa.

### 3. Descartado a propósito: subir la cuantización (Q5_K_M / Q6_K)

Se evaluó el 2026-09-25 y **se decidió NO hacerlo**. Motivos, con números:

| Quant | Tamaño | Decode esperado |
|---|---|---|
| Q4_K_M (actual) | 22,13 GB | ~11 t/s |
| UD-Q5_K_M | 26,46 GB | ~9,2 t/s |
| UD-Q6_K | 29,31 GB | ~8,3 t/s |

La ganancia de calidad de Q4->Q6 en un 35B es pequeña y no se nota en uso normal; la pérdida de
velocidad (25%) se paga en **cada** petición. `Q4_K_M` ya es el punto dulce.

Si algún día se revisa, el artefacto verificado es
`unsloth/Qwen3.6-35B-A3B-GGUF -> Qwen3.6-35B-A3B-UD-Q6_K.gguf`:
29.308.320.736 bytes, sha256
`4fe53b148b46f9b88830e2a3055c5b15c3a4d1e3ddc9a1384a108d8b9d59f043`, revisión
`a483e9e6cbd595906af30beda3187c2663a1118c`. El `mmproj` local ya sirve (899.283.680 bytes,
coincide exacto con `mmproj-F16.gguf` del repo) — **no re-descargar**.

## Otros hallazgos sin resolver

- **`README.md` desactualizado.** Describe un stack que ya no existe: "K2-Horizon-7B-Q4_K_M",
  contenedor `llama-core`, fork MoVA/K2. Lo que corre es Qwen3.6-35B-A3B en `llama-qwen`.
  Reescribir o marcar la nota como histórica.
- **`/ollama/*` NO es retirable** sin actualizar `aios-agent/setup.py` (líneas 872, 876, 1112) y
  reconstruir la ISO: la URL va escrita dentro de las ISOs ya distribuidas.
- **Ollama sigue arriba** (`127.0.0.1:11434`) con `qwen3.5:0.8b` (1 GB). No lo usa nadie.
- **Modelos huérfanos** en `models/`: `Qwen3.5-0.8B-Q4_K_M.gguf` (508 MB, era de la ruta `/shell`
  ya retirada) y `Qwen_Qwen3.5-9B-Q4_K_M.gguf` (5,8 GB). Ninguno se carga.
- **Restos ignorados por git** (no molestan, decisión pendiente): `.bak-qwen36/` (44K),
  `entrypoint.sh.k2`, `entrypoint-qwen36.sh.bak-sampling-20260912-210028`, `bin.fork-k2/` +
  `lib.fork-k2/` (51 MB).
- **Higiene del token:** `~/.local/bin/.git-askpass-github` da a cualquier proceso que corra como
  `ccmai` el token `ghp_` de `~/info.txt`, con acceso a los 6 repos privados. Valorar un token
  *fine-grained* limitado a los repos necesarios.
