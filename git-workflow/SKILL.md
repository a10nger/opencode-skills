---
name: Git Workflow
description: Работа с git на Windows — коммиты, ветки, worktree, конфликты, переводы строк, история и её очистка. Использовать при любых операциях с репозиториями.
---

# Git Workflow

`git` = `C:\Program Files\Git\cmd\git.exe`, `gh` не установлен (релизы/PR — только через git + веб).

## Коммиты

Формат: `<scope>: <что сделано>` — императив, английский, до 72 символов.

```
config: route local-worker to qwen3:8b
skills: add windows-admin skill
fix(plugin): stop autostart when port busy
```

- Один коммит — одно логическое изменение. Не смешивать рефакторинг и фикс.
- Тело коммита — только если нужно объяснить **почему**, не «что».
- Не коммитить сгенерированное: `node_modules`, `dist`, `*.log`, `.env`.

## Ветки

```
feat/<короткое-имя>
fix/<короткое-имя>
chore/<короткое-имя>
```

Перед началом работы: `git status` и `git branch --show-current`. Незакоммиченные чужие правки не трогать — это может быть работа пользователя.

## Worktree

Для параллельной работы без переключения веток — инструменты OpenCode:
`tools.opencode.worktree_create({name})` → каталог; `worktree_list()`; `worktree_remove({directory})`.

После создания worktree, если он становится основным рабочим каталогом, вызвать `tools.opencode.session_move({directory})` — иначе относительные пути будут указывать не туда.

## Переводы строк

Репозиторий держим в LF, рабочую копию — LF. В `.gitattributes`:
```
* text=auto eol=lf
*.ps1 text eol=crlf
*.bat text eol=crlf
```
Иначе PowerShell-скрипты с LF ломаются на некоторых вызовах, а diff показывает весь файл изменённым.

## Конфликты

```powershell
git status --short          # UU = конфликт
git diff --name-only --diff-filter=U
```
Разрешать по одному файлу, затем `git add <file>`, никогда не `git add -A` при незавершённом merge. Если конфликт в сгенерированном файле — перегенерировать, а не править руками.

## История

```powershell
git log --oneline -15
git log -p --follow -- <file>
git diff HEAD~1 --stat
git show <sha>:<path>       # версия файла до удаления
```

Откат:
- `git restore <file>` — выбросить правки в рабочей копии;
- `git restore --staged <file>` — убрать из индекса;
- `git revert <sha>` — безопасно для уже запушенного;
- `git reset --hard` — **только** с явного согласия пользователя, теряет данные.

## Секреты в истории

Если в коммит попал ключ — ротация ключа обязательна, чистка истории вторична. `git filter-repo` переписывает SHA и ломает чужие клоны; без подтверждения не запускать. Быстрая проверка:
```powershell
git log -p --all | Select-String -Pattern 'sk-|ghp_|AKIA|BEGIN .*PRIVATE KEY'
```

## Полезное

```powershell
git stash push -m "wip: <тема>"
git stash list
git branch -vv                 # какие ветки отстали
git remote -v
git config --get core.autocrlf # должно быть false при .gitattributes
```
