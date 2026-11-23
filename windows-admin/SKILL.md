---
name: Windows Admin
description: Администрирование Windows 11 через PowerShell — службы, планировщик, ACL, реестр, сетевые шары, Defender, группы и права. Использовать при любых задачах настройки этой машины.
---

# Windows Admin

## Машина (проверено)

| | |
|---|---|
| OS | Windows 11 Pro, build 26300 |
| Shell | **Windows PowerShell 5.1** (pwsh 7 НЕ установлен) |
| CPU / RAM | i7-13620H (10 cores) / 15.7 GB |
| GPU | RTX 4060 Laptop (8 GB VRAM) + Intel UHD |
| Git | `C:\Program Files\Git\cmd\git.exe` |
| `gh` | не установлен |

Следствия: нет `&&`, `??`, тернарника, `-Parallel`, `Get-Content -AsByteStream`.
Конвейер из двух команд — через `;` или отдельными строками, не `&&`.

## Правила работы

1. Сначала **читать** текущее состояние (`Get-*`), потом менять. Не «починить на глаз».
2. Любое изменение системы — только с подтверждением пользователя, если оно необратимо.
3. Не ставить софт на `C:`; всё в `D:\Apps\<program>`.
4. Перед правкой реестра — экспорт ветки в `C:\Users\zhega\AppData\Local\Temp\opencode\`.
5. Проверять результат **после** изменения, а не считать успех по отсутствию ошибки.

## Частые операции

```powershell
# Служба
Get-Service <name> | Select-Object Name,Status,StartType
Set-Service <name> -StartupType Automatic
Start-Service <name>

# Планировщик
Get-ScheduledTask -TaskName <name> | Select-Object TaskName,State
Get-ScheduledTask -TaskName <name> | Get-ScheduledTaskInfo   # LastRunTime, LastTaskResult
Register-ScheduledTask -Xml (Get-Content task.xml -Raw) -TaskName <name> -Force
Unregister-ScheduledTask -TaskName <name> -Confirm:$false
# LastTaskResult: 0 = успех, 0x41301 = выполняется, 0x1 = неверные аргументы

# Права на файл/ключ
icacls "D:\path"
icacls "D:\path" /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T
Get-Acl HKLM:\SOFTWARE\<key> | Format-List

# Сетевые шары
Get-SmbShare
New-SmbShare -Name <n> -Path "D:\share" -FullAccess "BUILTIN\Administrators"
Get-SmbSession | Select-Object ClientComputerName,NumOpens

# Реестр
Get-ItemProperty 'HKLM:\SOFTWARE\<key>'
Set-ItemProperty 'HKLM:\SOFTWARE\<key>' -Name X -Value 1
```

## Defender — критично

`Set-MpPreference -DisableRealtimeMonitoring $true` **не работает**, если включён Tamper Protection (а он включён по умолчанию на Win11). Команда вернёт успех и ничего не изменит.

Проверка реального состояния:
```powershell
Get-MpComputerStatus | Select-Object RealTimeProtectionEnabled,IsTamperProtected,AntivirusEnabled
```

Tamper Protection отключается только вручную в `Windows Security → Virus & threat protection → Manage settings`. Если задача требует отключить — сначала сообщить это пользователю, не изобретать обходы через реестр и задачи планировщика.

## Группы и пользователи
```powershell
Get-LocalGroupMember -Group Administrators
Add-LocalGroupMember -Group <g> -Member <u>
whoami /priv          # фактические привилегии процесса
```

## Диагностика
```powershell
Get-WinEvent -LogName System -MaxEvents 50 | Where-Object LevelDisplayName -in 'Error','Critical'
Get-NetTCPConnection -State Listen | Sort-Object LocalPort
Test-NetConnection <host> -Port <p>
Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID,@{n='FreeGB';e={[math]::Round($_.FreeSpace/1GB,1)}}
```

## Типовые грабли

- **Кодировка**: вывод в файл без явной кодировки даст UTF-16 или mojibake. Всегда `Set-Content -Encoding UTF8`.
- **`$LASTEXITCODE`** не сбрасывается сам — проверять сразу после вызова exe.
- **Ошибки не останавливают скрипт** по умолчанию: `$ErrorActionPreference = 'Stop'` в начале.
- **`Get-ChildItem` не видит скрытые** каталоги без `-Force`.
- **UAC**: процесс без elevation молча получит отказ на HKLM/Program Files. Проверять `whoami /priv | Select-String SeDebug`.
- **Долгие операции** — `Start-Process -Wait -NoNewWindow`, а не `&` с таймаутом.

## Отчёт

Коротко: что изменил, чем проверил, что осталось. Полные логи не пересказывать — путь к файлу.
