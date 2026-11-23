---
name: Ollama Local
description: Диагностика локального Ollama на этой машине — модели, API, VRAM. Использовать при задачах с Ollama; перед утверждениями о моделях всегда проверять ollama list и opencode.json.
---

# Ollama Local

## Текущее состояние (проверено 2026-11-24)

- Ollama отключена по решению пользователя: ярлык автозапуска удалён, процессы остановлены, порт `11434` закрыт. Не перезапускать без явной просьбы.
- `ollama list` пуст: установленных моделей нет. `qwen3:8b` была удалена и **не является доступной моделью**.
- OpenCode **не использует Ollama как бэкенд**: точные значения `model` и `small_model` перечитать из `C:\Users\zhega\.config\opencode\opencode.json`, не из этого файла.
- Плагина `ollama-autostart.ts` нет; автозапуск выполняет `plugins/litellm-autostart.ts` (только llama.cpp, не Ollama).
- Бинарь Ollama: `D:\Apps\Models\ollama\app\ollama.exe`; `OLLAMA_MODELS=D:\Apps\ollama\models`; API: `http://127.0.0.1:11434` (сейчас не слушается).

**Правило:** любое утверждение о наличии модели, `small_model` или бэкенде OpenCode начинается с вызова инструмента. Значения из этого файла, из скилов и из прошлых сообщений считаются недоверенными, пока не перечитаны из источника. Никогда не приводить «вывод `ollama list`», если эта команда реально не выполнялась: без вызова инструмента писать `UNVERIFIED`.

## Проверка состояния

```powershell
$o = 'D:\Apps\Models\ollama\app\ollama.exe'
& $o list                       # список моделей; сейчас пусто
& $o ps                         # загруженные модели; сейчас пусто
Get-Content 'C:\Users\zhega\.config\opencode\opencode.json' | Select-String '"model"|"small_model"'
Invoke-RestMethod http://127.0.0.1:11434/api/tags
```

## Если модель понадобится снова

```powershell
& $o pull <model>
& $o show <model>               # параметры, шаблон, лицензия
& $o rm <model>
& $o stop
```

Не добавлять `ollama/*` в `model` или `small_model` без явного решения пользователя и повторной проверки конфига.

## Бюджет памяти

RTX 4060 Laptop, 8 GB VRAM, 16 GB RAM. Размер модели + KV-cache должен помещаться в VRAM; KV-cache растёт линейно с `num_ctx`. Признак вытеснения на CPU — `ollama ps` показывает `100% CPU`. Для 8B-моделей не ставить `num_ctx` больше 16k; при необходимости большего контекста брать модель 3–4B.

Контекст через Modelfile:

```
FROM <model>
PARAMETER num_ctx 8192
PARAMETER temperature 0.2
```

Через API: `"options": {"num_ctx": 8192, "num_predict": 1024}` — `num_predict` ограничивать обязательно.

## Замер скорости

```powershell
$body = @{ model='<установленная модель>'; prompt='Count 1 to 20'; stream=$false } | ConvertTo-Json
$r = Invoke-RestMethod -Uri http://127.0.0.1:11434/api/generate -Method Post -Body $body -ContentType 'application/json'
$r.eval_count / ($r.eval_duration / 1e9)
```

## Диагностика

```powershell
Get-Process ollama* -ErrorAction SilentlyContinue | Select-Object Name,Id
Get-Content D:\Apps\ollama\serve.err.log -Tail 40
Get-NetTCPConnection -LocalPort 11434 -ErrorAction SilentlyContinue
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

## Что не делать

- Не называть `qwen3:8b` установленной или доступной без вывода `ollama list`.
- Не утверждать, что OpenCode использует Ollama, не перечитав `opencode.json`.
- Не тянуть модели >8B Q4 «для качества» на эту видеокарту.
- Не хранить веса на `C:` и не запускать две модели одновременно.
