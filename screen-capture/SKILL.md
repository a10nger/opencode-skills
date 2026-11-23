# Capture Screen

Снятие скриншота экрана Windows по запросу и показ его агенту через встроенный инструмент `read` (изображения поддерживает).

## Когда использовать

Пользователь просит «посмотри экран», «скриншот экрана», «какой сейчас экран», «покажи что на мониторе».

## Workflow

1. Запустить скрипт:
   ```powershell
   powershell -ExecutionPolicy Bypass -File <base>\scripts\capture-screen.ps1
   ```
2. Скрипт выводит строку вида `SHOT:<путь>`.
3. Инструментом `read` прочитать PNG по этому пути — модель получит изображение и опишет, что на экране.
4. Путь и описание кратко вернуться пользователю.

## Скрипт

```powershell
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$screen = [System.Windows.Forms.Screen]::PrimaryScreen
if (-not $screen -or -not $screen.Bounds -or $screen.Bounds.Width -le 0) { Write-Output 'FAILED:no-screen'; exit 1 }
$w = [int]$screen.Bounds.Width
$h = [int]$screen.Bounds.Height
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($screen.Bounds.X, $screen.Bounds.Y, 0, 0, $screen.Bounds.Size)
$dir = Join-Path $env:LOCALAPPDATA 'Temp\opencode\screens'
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$file = Join-Path $dir ('shot_{0}.png' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output "SHOT:$file"
```

## Ограничения

- `read` принимает PNG/JPG до 20 MiB — скриншот FullHD/4K (≈2–8 МБ) вписывается.
- Экран — PrimaryScreen; для нескольких мониторов — уточнять у пользователя, какой.
- DPI: `CopyFromScreen` снимает в физических пикселях — корректно.
- Скриншот — не есть «видение» в реальном времени: экран обновляется при каждом новом запросе. Если нужен мониторинг/видео — отдельная задача (например, `browser` namespace в desktop app для прикреплённой вкладки).

## Не использовать

- Для просмотра веб-страниц — браузерный namespace (`tools.browser` через execute), а не скриншот экрана.
- Не сохранять скриншоты в репо — только Temp.
