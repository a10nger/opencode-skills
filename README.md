# opencode-skills

Каталог скилов для [OpenCode](https://opencode.ai/docs/skills/).

Репозиторий публичный: скилы — это инструкции, а не секреты. Основной источник — HTTP-каталог на GitHub Pages; локальный клон на `D:` нужен только как fallback для машинно-специфичных скилов.

## Подключение (основной способ)

В `%USERPROFILE%\.config\opencode\opencode.json`:

```jsonc
{
  "skills": ["https://a10nger.github.io/opencode-skills/"]
}
```

Это base URL каталога: OpenCode сам читает `index.json` и скачивает файлы по `<base>/<skill-id>/<file>`. Токен не нужен, на `C:` ничего не клонируется.

## Структура

```
index.json                      каталог: имена, версии и файлы скилов
<skill-id>/SKILL.md             один скил = один каталог
<skill-id>/scripts/...          опциональные вспомогательные файлы
```

## Fallback: локальный клон на `D:`

Только для скилов, завязанных на конкретную машину (пути, железо, локальная модель):

```powershell
git clone https://github.com/a10nger/opencode-skills.git D:\Apps\opencode-skills
```

```jsonc
{
  "skills": [
    "https://a10nger.github.io/opencode-skills/",
    "D:/Apps/opencode-skills"
  ]
}
```

## Обновление

1. Правим файлы скила в репозитории (ветка `main`).
2. Если изменилось содержимое файла скила — инкрементируем его `version` в `index.json`, иначе OpenCode возьмёт старую версию из кэша.
3. Коммит и push в `main`: GitHub Pages пересобирает сайт (`.nojekyll` отключает Jekyll), дожидаемся статуса `built`.
4. Проверяем, что `https://a10nger.github.io/opencode-skills/index.json` отдаёт 200 и каждый файл из `files` доступен по `<base>/<name>/<file>`.

README в каталог скилов не входит, поэтому его правка не требует смены версий. `git pull` локального клона — только обновление fallback-копии, а не основной путь.

## Скилы

| ID | Назначение |
|---|---|
| `debug-powershell` | Провалы PowerShell 5.1: `&&`, BOM, `$LASTEXITCODE`, JSON, фоновые процессы |
| `docs-lookup` | Актуальная документация API/CLI через websearch/webfetch, выжимка в файл |
| `git-workflow` | Git на Windows: коммиты, ветки, worktree, CRLF, откаты, секреты в истории |
| `mcp-setup` | MCP в OpenCode V2, OAuth, ключи через env, HTTP-каталоги скилов |
| `secrets-audit` | Поиск утёкших ключей в файлах, конфигах и git-истории |
| `screen-capture` | Скриншоты и захват экрана, `scripts/capture-screen.ps1` |
| `windows-admin` | Windows 11: службы, планировщик, ACL, реестр, шары, Defender |
| `beads` | Память и задачи через `bd` (GitHub-backed issue tracker) |
| `browserbase` | Браузерные сценарии через удалённый MCP Browserbase |
| `exa` | Поиск и выборка через exa |
| `telegram` | Работа с Telegram |
