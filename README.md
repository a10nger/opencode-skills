# opencode-skills

Каталог скилов для [OpenCode](https://opencode.ai/docs/skills/).

Скилы специфичны для одной машины (Windows 11, PowerShell 5.1, локальный Ollama на RTX 4060), поэтому репозиторий приватный.

## Структура

```
index.json                      каталог для HTTP-режима
<skill-id>/SKILL.md             один скил = один каталог
<skill-id>/scripts/...          опциональные вспомогательные файлы
```

## Подключение локально

Каталог клонируется на `D:`, чтобы не занимать `C:`:

```powershell
git clone https://github.com/a10nger/opencode-skills.git D:\Apps\opencode-skills
```

В `%USERPROFILE%\.config\opencode\opencode.json`:

```jsonc
{
  "skills": ["D:/Apps/opencode-skills"]
}
```

Обновление: `git -C D:\Apps\opencode-skills pull`.

## Почему не GitHub Pages

HTTP-каталог (`skills: ["https://..."]`) не поддерживает авторизацию, а Pages для приватных репозиториев требует платного плана. Поэтому источник — локальный клон на `D:`.

Если понадобится настоящий HTTP-каталог: репозиторий должен стать публичным и получить Pages, тогда в конфиг идёт `https://a10nger.github.io/opencode-skills/`.

## Скилы

| ID | Назначение |
|---|---|
| `windows-admin` | Windows 11 / PowerShell 5.1: службы, планировщик, ACL, реестр, шары, Defender |
| `ollama-local` | Локальный Ollama, VRAM-бюджет, `num_ctx`, замер tok/s, пределы 8B |
| `debug-powershell` | Провалы PS 5.1: нет `&&`, BOM, `$LASTEXITCODE`, JSON, процессы |
| `git-workflow` | Коммиты, ветки, worktree, CRLF, откаты, секреты в истории |
| `secrets-audit` | Скан ключей в файлах и git-истории + `scripts/scan-secrets.ps1` |
| `docs-lookup` | Документация через websearch/webfetch, выжимка в файл |
| `mcp-setup` | MCP в OpenCode V2, OAuth, HTTP-каталоги скилов |
