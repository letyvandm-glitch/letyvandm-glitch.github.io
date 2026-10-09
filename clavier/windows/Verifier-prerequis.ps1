# Verifie les prerequis du clavier et propose de les telecharger / installer.
# Texte volontairement sans accents (compatibilite de la console Windows).
$ErrorActionPreference = 'Stop'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$here      = Split-Path -Parent $MyInvocation.MyCommand.Path
$store     = Join-Path $env:LOCALAPPDATA 'ClavierCH57x'
$toolLocal = Join-Path $here 'ch57x-keyboard-tool.exe'
$toolStore = Join-Path $store 'ch57x-keyboard-tool.exe'
$ua        = @{ 'User-Agent' = 'ClavierLauncher' }

function Test-Usbdk {
    $dirs = @("$env:ProgramFiles\UsbDk Runtime Library", "${env:ProgramFiles(x86)}\UsbDk Runtime Library")
    foreach ($d in $dirs) { if (Test-Path -LiteralPath $d) { return $true } }
    if (Get-Service -Name 'UsbDk' -ErrorAction SilentlyContinue) { return $true }
    return $false
}
function Test-Tool { return ((Test-Path -LiteralPath $toolLocal) -or (Test-Path -LiteralPath $toolStore)) }

function Get-Asset($repo, $pattern) {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -Headers $ua
    $asset = $rel.assets | Where-Object { $_.name -match $pattern } | Select-Object -First 1
    if (-not $asset) { throw "Aucun fichier correspondant dans la derniere version de $repo" }
    return $asset
}

function Install-Tool {
    $asset = Get-Asset 'kriomant/ch57x-keyboard-tool' 'windows.*\.(zip|exe)$|\.exe$'
    Write-Host "  Telechargement de $($asset.name) ..."
    $tmp = Join-Path $env:TEMP ('clavier-tool-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    $file = Join-Path $tmp $asset.name
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $file -UseBasicParsing -Headers $ua
    New-Item -ItemType Directory -Force -Path $store | Out-Null
    if ($asset.name -match '\.zip$') {
        Expand-Archive -LiteralPath $file -DestinationPath $tmp -Force
        $exe = Get-ChildItem -Path $tmp -Recurse -Filter 'ch57x-keyboard-tool.exe' | Select-Object -First 1
        if (-not $exe) { throw "ch57x-keyboard-tool.exe est introuvable dans l'archive" }
        Copy-Item -LiteralPath $exe.FullName -Destination $toolStore -Force
    } else {
        Copy-Item -LiteralPath $file -Destination $toolStore -Force
    }
    $hash = (Get-FileHash -LiteralPath $toolStore -Algorithm SHA256).Hash
    Write-Host "  Outil installe : $toolStore"
    Write-Host "  SHA256 : $hash"
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

function Install-Usbdk {
    $asset = Get-Asset 'daynix/UsbDk' 'x64.*\.msi$'
    Write-Host "  Telechargement de $($asset.name) ..."
    $msi = Join-Path $env:TEMP $asset.name
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $msi -UseBasicParsing -Headers $ua
    Write-Host "  SHA256 : $((Get-FileHash -LiteralPath $msi -Algorithm SHA256).Hash)"
    Write-Host "  Installation (Windows va demander l'autorisation administrateur) ..."
    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/i', "`"$msi`"", '/passive', '/norestart') -Verb RunAs -Wait -PassThru
    if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) { throw "Installation de USBDK terminee avec le code $($p.ExitCode)" }
    if ($p.ExitCode -eq 3010) { Write-Host "  Un redemarrage de Windows est necessaire pour finir l'installation." }
    Remove-Item -LiteralPath $msi -Force -ErrorAction SilentlyContinue
}

$needUsbdk = -not (Test-Usbdk)
$needTool  = -not (Test-Tool)
if (-not $needUsbdk -and -not $needTool) { Write-Host 'Prerequis OK (pilote USBDK et outil ch57x presents).'; exit 0 }

Write-Host ''
Write-Host 'Prerequis manquants pour programmer le clavier :'
if ($needUsbdk) { Write-Host '  - USBDK (pilote USB) : https://github.com/daynix/UsbDk/releases' }
if ($needTool)  { Write-Host '  - ch57x-keyboard-tool (outil officiel) : https://github.com/kriomant/ch57x-keyboard-tool/releases' }
Write-Host '(Ils ne servent qu''a la programmation par l''outil ; la page web, elle, n''en a pas besoin.)'
$ans = Read-Host 'Telecharger et installer maintenant depuis les pages officielles ci-dessus ? (O/N)'
if ($ans -notmatch '^[oOyY]') { Write-Host 'Installation ignoree.'; exit 0 }

if ($needTool) {
    try { Write-Host 'Outil ch57x-keyboard-tool :'; Install-Tool }
    catch { Write-Host "  ECHEC : $($_.Exception.Message)"; Write-Host '  Telechargez-le a la main (lien ci-dessus).' }
}
if ($needUsbdk) {
    try { Write-Host 'Pilote USBDK :'; Install-Usbdk; Write-Host '  Debranchez puis rebranchez le clavier.' }
    catch { Write-Host "  ECHEC : $($_.Exception.Message)"; Write-Host '  Installez-le a la main (lien ci-dessus).' }
}
exit 0
