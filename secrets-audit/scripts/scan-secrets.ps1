param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [switch]$GitHistory,
    [switch]$IncludeLogs
)

$ErrorActionPreference = 'Stop'

$patterns = [ordered]@{
    'openai'        = 'sk-[A-Za-z0-9]{20,}'
    'openai-proj'   = 'sk-proj-[A-Za-z0-9_\-]{20,}'
    'anthropic'     = 'sk-ant-[A-Za-z0-9_\-]{20,}'
    'github-pat'    = 'gh[pousr]_[A-Za-z0-9]{36,}'
    'aws'           = 'AKIA[0-9A-Z]{16}'
    'slack'         = 'xox[abps]-[A-Za-z0-9\-]{10,}'
    'google-api'    = 'AIza[0-9A-Za-z_\-]{35}'
    'jwt'           = 'eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.'
    'private-key'   = '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    'generic-assign'= '(?i)(password|pwd|secret|token|apikey|api_key)\s*[:=]\s*[''"]?[^\s''"]{8,}'
}

$excludeDirs = @('node_modules', '.git', 'dist', 'build', 'vendor', '__pycache__', '.venv', 'venv')
$fileExtensions = @('.env', '.json', '.jsonc', '.ps1', '.psm1', '.sh', '.bat', '.cmd', '.yml', '.yaml',
                   '.ts', '.js', '.py', '.toml', '.ini', '.cfg', '.conf', '.md', '.txt', '.xml')

function Test-Excluded {
    param([string]$FullName)
    foreach ($d in $excludeDirs) {
        if ($FullName -match [regex]::Escape("\$d\")) { return $true }
    }
    return $false
}

function Find-InText {
    param([string]$Text, [string]$Source)
    $hits = 0
    foreach ($name in $patterns.Keys) {
        foreach ($m in [regex]::Matches($Text, $patterns[$name])) {
            $value = $m.Value
            $masked = if ($value.Length -gt 10) { $value.Substring(0, 6) + '...' } else { '***' }
            $line = ($Text.Substring(0, $m.Index) -split "`n").Count
            "{0}:{1}:{2}: {3}" -f $Source, $line, $name, $masked
            $hits++
        }
    }
    return $hits
}

$total = 0

if (-not (Test-Path -LiteralPath $Path)) { throw "Path not found: $Path" }

Write-Host "Scanning $Path" -ForegroundColor Cyan

$files = Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
    -not (Test-Excluded $_.FullName) -and
    ($fileExtensions -contains $_.Extension.ToLower() -or $_.Name -like '.env*') -and
    ($IncludeLogs -or $_.Extension -ne '.log')
}

foreach ($f in $files) {
    if ($f.Length -gt 2MB) { continue }
    try {
        $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8 -ErrorAction Stop
    } catch { continue }
    if ([string]::IsNullOrWhiteSpace($text)) { continue }
    $total += Find-InText -Text $text -Source $f.FullName
}

if ($GitHistory) {
    if (-not (Test-Path -LiteralPath (Join-Path $Path '.git'))) {
        Write-Warning "No .git in $Path, skipping history"
    } else {
        Push-Location -LiteralPath $Path
        try {
            $log = git log -p --all 2>$null | Out-String
            foreach ($name in $patterns.Keys) {
                foreach ($m in [regex]::Matches($log, $patterns[$name])) {
                    $v = $m.Value
                    $masked = if ($v.Length -gt 10) { $v.Substring(0, 6) + '...' } else { '***' }
                    "git-history:{0}: {1}" -f $name, $masked
                    $total++
                }
            }
        } finally { Pop-Location }
    }
}

Write-Host ""
Write-Host ("Findings: {0}" -f $total) -ForegroundColor $(if ($total -gt 0) { 'Yellow' } else { 'Green' })
if ($total -gt 0) { exit 1 } else { exit 0 }
