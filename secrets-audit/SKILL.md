---
name: Secrets Audit
description: Поиск утёкших секретов — API-ключи, токены, пароли в файлах, конфигах и git-истории. Использовать перед публикацией репозитория, отправкой файлов или при подозрении на утечку.
---

# Secrets Audit

## Порядок

1. **Сканировать рабочую копию** (быстро, безопасно).
2. **Сканировать git-историю** (медленнее, показывает уже «забытые» ключи).
3. Для каждого находки: определить, живой ли ключ, и **ротировать**.

Главное правило: **чистка файла не отменяет ротацию**. Если ключ попал в коммит, он считается скомпрометированным, даже если коммит удалён.

## Готовый скрипт

`scripts/scan-secrets.ps1` — скан каталога и/или git-истории, вывод в формате `файл:строка:тип`.

```powershell
pwsh -File .\scripts\scan-secrets.ps1 -Path C:\work\repo
```

Без `pwsh` (здесь только 5.1):
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\scan-secrets.ps1 -Path C:\work\repo
```

## Что ищем

| Тип | Шаблон |
|---|---|
| OpenAI | `sk-[A-Za-z0-9]{20,}` |
| OpenAI project | `sk-proj-[A-Za-z0-9_-]{20,}` |
| Anthropic | `sk-ant-[A-Za-z0-9_-]{20,}` |
| GitHub PAT | `gh[pousr]_[A-Za-z0-9]{36,}` |
| AWS | `AKIA[0-9A-Z]{16}` |
| Slack | `xox[abps]-[A-Za-z0-9-]{10,}` |
| Google API | `AIza[0-9A-Za-z_-]{35}` |
| JWT | `eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.` |
| Private key | `-----BEGIN [A-Z ]*PRIVATE KEY-----` |
| Connection string | `(password|pwd|secret|token|apikey|api_key)\s*[:=]\s*['"]?[^\s'"]{8,}` |

## Где смотреть в первую очередь

```
.env, .env.*, *.env
opencode.json, opencode.jsonc, config.json, settings.json
*.ps1, *.psm1, *.sh, *.bat  (захардкоженные параметры)
.git/config  (токены в remote URL)
Dockerfile, docker-compose.yml
*.log  (часто печатают заголовки запросов)
```

На этой машине отдельно проверить `C:\Users\zhega\.config\opencode\` и `C:\Users\zhega\AppData\Local\Temp\opencode\` — там лежат скрипты и логи прошлых сессий.

## Git-история

```powershell
git -C <repo> log -p --all | Select-String -Pattern 'sk-|ghp_|AKIA|BEGIN .*PRIVATE KEY' -Context 0,2
git -C <repo> log --all --diff-filter=D --name-only --pretty=format:%h | Select-String '.env'
```
Файл удалён, но остался в старых коммитах — типичный случай.

## Если `gh` нет

Репозиторий публичный, а `gh` не установлен: проверять через `https://github.com/<owner>/<repo>/blob/<sha>/<path>` руками или через API (`webfetch` на `https://api.github.com/repos/.../contents/<path>`). Не устанавливать `gh` без спроса.

## После находки

1. Сообщить тип и место, **сам ключ не печатать целиком** (маскировать: первые 6 + `…`).
2. Ротировать в сервисе-владельце.
3. Убрать из файла, добавить файл в `.gitignore`.
4. Если ключ в истории и репозиторий общий — сообщить пользователю, что нужен `git filter-repo` и что это перепишет SHA. Без явного согласия не запускать.
5. Для локальных конфигов — перевести на переменные окружения или `opencode auth`, если сервис это поддерживает.

## Ложные срабатывания

Тестовые ключи (`sk-test`, `xxx`), примеры в документации, base64 от не-секретов, хэши коммитов. Проверять контекст строки перед выводом «утечка».
