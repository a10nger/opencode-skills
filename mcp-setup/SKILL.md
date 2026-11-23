---
name: MCP Setup
description: Подключение MCP-серверов и удалённых каталогов скилов в OpenCode без мусора на диске C: — удалённые серверы, OAuth, HTTP-каталоги скилов, проверка и отключение. Использовать при настройке MCP, шаринге скилов и вопросе «чтобы не засерать ПК».
---

# MCP Setup

Принцип этой машины: `C:` не засоряем. Значит — **удалённые MCP-серверы** (Streamable HTTP) вместо локальных `npx`, и **HTTP-каталоги скилов** вместо папок в `~/.config`.

Локальные MCP через `npx` тянут пакеты в `%LOCALAPPDATA%\npm-cache` на `C:`. Разрешены, только если сервер больше никак не достать, и с кэшем на другом диске.

## Удалённый MCP (предпочтительно)

CLI:
```powershell
opencode mcp add context7 --global --url https://mcp.context7.com/mcp
opencode mcp list
```

Вручную — `opencode.json`, схема V2: серверы лежат в `mcp.servers`, **не** прямо в `mcp`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "context7": {
        "type": "remote",
        "url": "https://mcp.context7.com/mcp"
      }
    }
  }
}
```

| Поле | Обязательно | Смысл |
|---|---|---|
| `type` | да | `"remote"` для HTTP, `"local"` для stdio-команды |
| `url` | да | абсолютный endpoint |
| `headers` | нет | ключи только через `{env:NAME}` |
| `oauth` | нет | по умолчанию включён; `false` — если только API-key |
| `disabled` | нет | `true` = настроен, но не подключается |
| `codemode` | нет | `false` — отдать тулы напрямую, а не через Code Mode |
| `pool` | нет | делить одно соединение между каталогами |
| `timeout` | нет | `startup` / `catalog` / `execution` в мс |

Важно: **`enabled` в V2 нет** — только `disabled`. `"enabled": true` молча игнорируется, сервер остаётся выключенным и это выглядит как «конфиг не работает».

## Ключи — не в файле

```jsonc
{
  "context7": {
    "type": "remote",
    "url": "https://mcp.context7.com/mcp",
    "oauth": false,
    "headers": { "CONTEXT7_API_KEY": "{env:CONTEXT7_API_KEY}" }
  }
}
```
`{env:NAME}` — единственная подстановка; `$NAME` в JSON **не** раскрывается. Сам ключ — в переменной окружения пользователя (`setx`), не в `opencode.json`.

## OAuth

```powershell
opencode mcp auth sentry
opencode mcp list        # ждём "connected", а не "needs authentication"
opencode mcp logout sentry
```
Если браузер не возвращается на callback (SSH/контейнер) — скопировать URL из адресной строки в приглашение.

## HTTP-каталог скилов (без файлов на диске)

Скилы можно не хранить локально: OpenCode умеет брать их с HTTP-каталога.

```jsonc
{
  "skills": [
    "https://example.com/opencode/skills/"
  ]
}
```

Каталог — это базовый URL с `index.json`:

```json
{
  "skills": [
    {
      "name": "git-release",
      "version": "3",
      "files": ["SKILL.md", "references/release-policy.md"]
    }
  ]
}
```

Файлы скачиваются с `<base>/git-release/<file>`. Требования:
- пути безопасные, относительные, same-origin;
- в списке обязателен `SKILL.md` (или `<name>.md`);
- `version` инкрементить при любом изменении, иначе сработает кэш и правки не подхватятся.

Что это даёт: скилы не лежат в `~/.config`, обновляются централизованно, `C:` не растёт. Минус — без сети скилов нет; поэтому локальный `skills/` оставляем как fallback для машинно-специфичных вещей (пути, железо, Ollama).

Где хостить каталог без своего сервера: GitHub Pages из отдельного репозитория (raw.githubusercontent **не** подходит — он не отдаёт вложенные пути как базовый URL), либо любой статический хостинг. Приватный вариант — свой маленький сервер, но это уже не «без мусора на ПК», а отдельная машина.

## Проверка

```powershell
opencode mcp list          # состояние: connected / needs authentication / failed
opencode mcp --help
```
В TUI — `/mcps`: подключить, отключить, авторизовать. Отключение в `/mcps` конфиг **не** меняет.

Дебаг подключения: поднять `opencode --log-level DEBUG`, смотреть лог сессии; для удалённого сервера проверить доступность `Test-NetConnection <host> -Port 443`.

## Права и контекст

MCP-тулы съедают контекст. Подключать только нужное, остальное — `disabled: true`.
Скрыть конкретный тул:
```jsonc
{
  "permissions": [
    { "action": "context7_*", "resource": "*", "effect": "deny" }
  ]
}
```
Имя тула — `<server>_<tool>`, недопустимые символы заменяются на `_`.

## Чек-лист «не засерать C:»

1. Сначала искать **удалённый** вариант сервера.
2. Если только локальный: `npm_config_cache=D:\Apps\node\npm-cache` перед `npx`.
3. Не ставить глобально (`npm i -g`) без нужды.
4. Скилы — через HTTP-каталог; локально только машинно-специфичные.
5. После добавления — `opencode mcp list` и проверка, что нет `failed`.
