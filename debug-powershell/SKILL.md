---
name: Debug PowerShell
description: Разбор типовых провалов PowerShell 5.1 в этом окружении — кодировки, кавычки, коды возврата, JSON, фоновые процессы, отсутствие pwsh 7. Использовать когда скрипт или команда ведёт себя не так, как ожидалось.
---

# Debug PowerShell

Здесь **Windows PowerShell 5.1** (`powershell.exe`), не `pwsh`. Всё, что ниже, проверено на этой машине.

## Синтаксис, которого нет в 5.1

| Не работает | Замена |
|---|---|
| `cmd1 && cmd2` | `cmd1; if ($?) { cmd2 }` или две строки |
| `a ?? b` | `if ($null -eq $a) { $b } else { $a }` |
| `$ok ? 'y' : 'n'` | `if ($ok) { 'y' } else { 'n' }` |
| `ForEach-Object -Parallel` | `Start-Job` / `Start-Process` |
| `Get-Content -AsByteStream` | `[IO.File]::ReadAllBytes()` |
| `Test-Json`, `Get-Content -Raw -Encoding utf8NoBOM` | вручную |

`&&` в PS 5.1 — это parse error `The token '&&' is not a valid statement separator`. Самая частая причина «скрипт не запускается».

## Кодировка

Проблема №1 с русским текстом.

```powershell
# запись — всегда явно
Set-Content -Path $p -Value $text -Encoding UTF8

# чтение
Get-Content $p -Raw -Encoding UTF8
```

- `Out-File` / `>` по умолчанию дают **UTF-16 LE** → файл «бинарный» для git и парсеров.
- Русский текст в `.ps1` **без BOM** PS 5.1 читает как ANSI → кракозябры в строках и путях. Сохранять `.ps1` с BOM (UTF-8 with BOM) или писать только ASCII.
- Консоль: `chcp 65001` меняет кодовую страницу только для текущего процесса и ломает вывод некоторых exe.

## Коды возврата

```powershell
& $exe args
$code = $LASTEXITCODE          # читать НЕМЕДЛЕННО
if ($code -ne 0) { throw "exit $code" }
```

`$LASTEXITCODE` не обнуляется, поэтому «успех» после предыдущей команды — иллюзия. И `2>$null` не делает команду успешной: смотреть код.

## Ошибки не останавливают скрипт

По умолчанию `$ErrorActionPreference = 'Continue'`: скрипт идёт дальше после ошибки, а код возврата 0. В начале любого скрипта:

```powershell
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
```

Исключение: `-ErrorAction SilentlyContinue` для «может не существовать» — осознанно, не глобально.

## Кавычки и подстановка

```powershell
# переменные НЕ подставляются
'D:\path\$name'
# подставляются
"D:\path\$name"
```
Регэкспы и `$` в строках — одинарные кавычки. Пути с пробелами — всегда в кавычках при вызове exe: `& 'C:\Program Files\x\y.exe'`.

`-Path` и `-LiteralPath`: второй не трактует `[`, `]`, `*` как маску. Для пользовательских путей — `-LiteralPath`.

## JSON

```powershell
$obj | ConvertTo-Json -Depth 10 -Compress
$raw | ConvertFrom-Json
```
Без `-Depth` глубже 2 уровней молча обрежется в строку. `ConvertFrom-Json` в 5.1 не даёт хэш-таблицу — свойства через `.`, `-AsHashtable` недоступен.

## Процессы и ожидание

```powershell
# правильно: дождаться и не плодить окна
Start-Process -FilePath $exe -ArgumentList $a -Wait -NoNewWindow -PassThru

# таймаут
$p = Start-Process ... -PassThru
if (-not $p.WaitForExit(30000)) { $p.Kill() }
```
`& $exe` блокирует, но не даёт таймаута. `Start-Job` — отдельный процесс без доступа к текущим переменным.

## Потоки вывода

```powershell
& $exe *>&1 | Tee-Object -FilePath $log   # всё в лог
& $exe 2>&1 | ForEach-Object { "$_" }      # stderr как строки
```
`2>$null` работает, `2> $null` с пробелом — тоже, но `>null` создаст файл `null`.

## Диагностика

```powershell
$PSVersionTable.PSVersion
Get-Command <name> -All | Select-Object Name,Source,Version
Trace-Command -Name ParameterBinding -Expression { <выражение> } -PSHost
Get-Help <cmd> -Full
$Error[0] | Format-List * -Force     # полная ошибка, включая ScriptStackTrace
```

## Порядок разбора

1. Воспроизвести минимальной командой (одна строка, без обёрток).
2. Проверить версию PS и наличие команды/модуля.
3. Проверить кодировку файла и консоли.
4. Проверить `$LASTEXITCODE` и `$Error[0]`, а не только текст на экране.
5. Только потом менять логику.
