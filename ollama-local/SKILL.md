---
name: Ollama Local
description: Работа с локальным Ollama на этой машине — модели, контекст, квантизация, скорость, настройка local-worker и small_model в OpenCode. Использовать при задачах с локальными моделями, GPU/VRAM и делегированием.
---

# Ollama Local

## Установка (проверено)

| | |
|---|---|
| Бинарь | `D:\Apps\ollama\app\ollama.exe` |
| Веса | `D:\Apps\ollama\models` (`OLLAMA_MODELS`) |
| Модели | `qwen3:8b` (Q4_K_M, 5.0 GB), GGUF-копия `models\gguf\Qwen3-8B-Q4_K_M.gguf` |
| GPU | RTX 4060 Laptop, **8 GB VRAM**, 16 GB RAM |
| API | `http://127.0.0.1:11434` (OpenAI-совместимый `/v1`) |

В `C:\Users\zhega\.config\opencode\opencode.json`:
- `small_model: ollama/qwen3:8b` — для служебных задач (заголовки, компакция);
- агент `local-worker` (`~/.config/opencode/agents/local-worker.md`) — исполнитель;
- плагин `plugins/ollama-autostart.ts` поднимает сервер.

## Основные команды

```powershell
$o = 'D:\Apps\ollama\app\ollama.exe'
& $o list
& $o ps                      # что загружено сейчас + размер в VRAM
& $o show qwen3:8b           # параметры, шаблон, лицензия
& $o pull <model>
& $o rm <model>
& $o stop
```

## Бюджет памяти — главное ограничение

8 GB VRAM. Прикидка: `вес_GB + KV-cache`. KV-cache растёт **линейно с `num_ctx`**.

- qwen3:8b Q4_K_M ≈ 5.0 GB + контекст.
- `num_ctx` 8192 → комфортно, ~6.5 GB, полностью на GPU.
- `num_ctx` 32768 → KV-cache ~2–3 GB, часть слоёв уходит на CPU, скорость падает в 3–5 раз.
- Признак вытеснения на CPU: `ollama ps` показывает `100% CPU` вместо `100% GPU`.

Правило: **не ставить `num_ctx` больше 16k** для 8B на этой карте. Если нужно больше контекста — брать модель 3–4B, а не расширять окно.

## Настройка контекста

Через Modelfile (постоянно):
```
FROM qwen3:8b
PARAMETER num_ctx 8192
PARAMETER temperature 0.2
```
`ollama create qwen3-8b-ctx8k -f Modelfile`

Через API (разово): `"options": {"num_ctx": 8192, "num_predict": 1024}`.
`num_predict` обязательно ограничивать — иначе модель генерит до упора и таймаут.

`keep_alive`: `-1` держит модель в VRAM вечно (быстро, но занимает память), `"5m"` — по умолчанию. Для `local-worker` держать `-1` смысла нет, если работа пачками.

## Замер скорости

```powershell
$body = @{ model='qwen3:8b'; prompt='Count 1 to 20'; stream=$false } | ConvertTo-Json
Measure-Command {
  $r = Invoke-RestMethod -Uri http://127.0.0.1:11434/api/generate -Method Post -Body $body -ContentType 'application/json'
} | Select-Object TotalSeconds
$r.eval_count / ($r.eval_duration / 1e9)   # tok/s
```
Ориентир для 4060 Laptop: 25–45 tok/s на 8B Q4 при полном GPU offload. Ниже 10 — модель на CPU, искать причину в контексте.

## Tool-calling и пределы 8B

qwen3:8b умеет tool calls, но:
- ломается на 3+ последовательных tool call в одном шаге;
- не держит длинные системные промпты (>2k токенов инструкций);
- путает аргументы, если у тула больше 4 параметров;
- на сложных edit-задачах (несколько несвязанных правок в файле) чаще всего проваливается.

Практика: один tool call на шаг, один файл на задачу, явные абсолютные пути, никакой двусмысленности. Провалился дважды на одном шаге — забирать задачу себе.

## Диагностика

```powershell
Get-Process ollama* -ErrorAction SilentlyContinue | Select-Object Name,Id,@{n='RAM_GB';e={[math]::Round($_.WorkingSet64/1GB,1)}}
Get-Content D:\Apps\ollama\serve.err.log -Tail 40
Invoke-RestMethod http://127.0.0.1:11434/api/tags   # сервер жив?
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

Сервер не отвечает → проверить, не занят ли порт 11434 другим процессом (`Get-NetTCPConnection -LocalPort 11434`), и лог `ollama-autostart.log` в Temp.

## Что не делать

- Не тянуть модели >8B Q4 на эту карту «для качества» — будет CPU-offload.
- Не хранить веса на `C:`.
- Не запускать две модели одновременно: 8 GB VRAM хватит только на одну.
