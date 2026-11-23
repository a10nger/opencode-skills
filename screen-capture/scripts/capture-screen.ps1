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
