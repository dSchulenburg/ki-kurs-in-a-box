# KI-Box auf einem frischen Windows-Rechner einrichten
# Git, WSL2, Docker Desktop, Node LTS, Gemini CLI, KI-Kurs-in-a-Box, MCP-Anbindung,
# dazu das Image der OER-Werkbank
#
# Aufruf: PowerShell ALS ADMINISTRATOR, dann dieses Skript ausfuehren.
# Das Skript ist wiederholbar. Wenn es "NEUSTART" meldet: neu starten,
# PowerShell wieder als Administrator oeffnen, dasselbe Skript noch einmal starten.
# Es macht dort weiter, wo es aufgehoert hat.
#
# Bewusst nur ASCII im Skript: Windows PowerShell 5.1 liest UTF-8 ohne BOM sonst falsch.

$ErrorActionPreference = 'Stop'

function Schritt($t) { Write-Host "`n== $t" -ForegroundColor Cyan }
function Ok($t)      { Write-Host "   ok: $t" -ForegroundColor Green }
function Hat($cmd)   { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function PfadNeu {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}
function Winget($id) {
    winget install --id $id -e --silent --accept-source-agreements --accept-package-agreements
    PfadNeu
}

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
         ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Write-Host 'Bitte PowerShell mit "Als Administrator ausfuehren" starten.' -ForegroundColor Red
    return
}
if (-not (Hat 'winget')) {
    Write-Host 'winget fehlt. Im Microsoft Store "App-Installer" installieren, dann erneut starten.' -ForegroundColor Red
    return
}

$neustart = $false

# --- 1. WSL2 (Grundlage fuer Docker Desktop) ---------------------------------
Schritt 'WSL2'
$wsl = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State
$vmp = (Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State
if ($wsl -ne 'Enabled' -or $vmp -ne 'Enabled') {
    wsl --install --no-distribution
    $neustart = $true
} else { Ok 'WSL2 ist aktiv' }

# --- 2. Git -------------------------------------------------------------------
Schritt 'Git'
if (-not (Hat 'git')) { Winget 'Git.Git' } else { Ok (git --version) }

# --- 3. Docker Desktop --------------------------------------------------------
Schritt 'Docker Desktop'
$dockerExe = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
if (-not (Test-Path $dockerExe)) {
    Winget 'Docker.DockerDesktop'
    $neustart = $true
} else { Ok 'installiert' }

# --- 4. Node LTS + Gemini CLI -------------------------------------------------
Schritt 'Node + Gemini CLI'
if (-not (Hat 'node')) { Winget 'OpenJS.NodeJS.LTS' } else { Ok "Node $(node --version)" }
if (-not (Hat 'gemini')) {
    npm install -g @google/gemini-cli
    PfadNeu
} else { Ok 'Gemini CLI vorhanden' }

# --- 5. Gemini mit der KI-Box verbinden (MCP) ---------------------------------
Schritt 'Gemini -> moodle-box (MCP)'
$gdir = Join-Path $HOME '.gemini'
$gset = Join-Path $gdir 'settings.json'
New-Item -ItemType Directory -Force $gdir | Out-Null
if (Test-Path $gset) { $cfg = Get-Content $gset -Raw | ConvertFrom-Json } else { $cfg = [pscustomobject]@{} }
if (-not $cfg.PSObject.Properties['mcpServers']) {
    $cfg | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([pscustomobject]@{})
}
$box = [pscustomobject]@{
    httpUrl = 'http://localhost:8000/mcp'
    headers = [pscustomobject]@{ 'x-api-key' = 'ki-kurs-lokal' }
}
$cfg.mcpServers | Add-Member -NotePropertyName 'moodle-box' -NotePropertyValue $box -Force
$cfg | ConvertTo-Json -Depth 10 | Set-Content $gset -Encoding UTF8
Ok "eingetragen in $gset"

if ($neustart) {
    Write-Host "`nNEUSTART noetig (WSL/Docker). Danach PowerShell als Administrator" -ForegroundColor Yellow
    Write-Host 'wieder oeffnen und dieses Skript noch einmal starten.' -ForegroundColor Yellow
    return
}

# --- 6. Docker starten und warten ---------------------------------------------
Schritt 'Docker-Engine'
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Start-Process $dockerExe
    Write-Host '   Docker Desktop startet. Beim ersten Mal die Lizenzbedingungen im Fenster bestaetigen.'
    $bis = (Get-Date).AddMinutes(4)
    do { Start-Sleep 5; docker info *> $null } while ($LASTEXITCODE -ne 0 -and (Get-Date) -lt $bis)
    if ($LASTEXITCODE -ne 0) {
        Write-Host '   Docker antwortet noch nicht. Warten, bis das Wal-Symbol ruhig ist, dann Skript erneut starten.' -ForegroundColor Yellow
        return
    }
}
Ok 'Docker laeuft'

# --- 7. KI-Box holen und starten ----------------------------------------------
Schritt 'KI-Kurs-in-a-Box'
$ziel = Join-Path $HOME 'ki-kurs-in-a-box'
if (-not (Test-Path $ziel)) {
    git clone https://github.com/dSchulenburg/ki-kurs-in-a-box.git $ziel
} else {
    git -C $ziel pull --ff-only
}
Push-Location $ziel
docker compose up -d
Pop-Location

# --- 8. Werkbank vorab ziehen -------------------------------------------------
# Nur das Image. Gestartet wird sie von Hand, damit man den Befehl sieht.
Schritt 'OER-Werkbank (Image)'
docker pull dadalama/oercamp-werkbank
Ok 'Werkbank-Image liegt bereit'

Write-Host "`nFertig." -ForegroundColor Green
Write-Host '  Moodle:  http://localhost:8080   (admin / KiKurs-Demo-2026)'
Write-Host '  Erststart dauert zwei bis drei Minuten. Fortschritt: docker compose logs -f moodle'
Write-Host "  Dann:    cd $ziel ; gemini   -> im Chat /mcp eingeben, moodle-box muss erscheinen"
Write-Host ''
Write-Host '  Werkbank in einem leeren Ordner starten:'
Write-Host '    mkdir $HOME\lernmodul; cd $HOME\lernmodul'
Write-Host '    docker run --rm -it -p 5173:5173 -v "${PWD}:/work" dadalama/oercamp-werkbank'
Write-Host '  Dann http://localhost:5173 oeffnen.'
