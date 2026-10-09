# Installe l'appli Clavier complete dans D:\Clavier-6T (copie locale + lanceurs) et propose un raccourci bureau.
# Texte volontairement sans accents (compatibilite de la console Windows).
$ErrorActionPreference = 'Stop'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$repo   = 'letyvandm-glitch/letyvandm-glitch.github.io'
$refs   = @('heads/main', 'heads/claude/clavier-6-touches-app-jkz9pd')
$dest   = 'D:\Clavier-6T'
$ua     = @{ 'User-Agent' = 'ClavierInstaller' }

if (-not (Test-Path -LiteralPath 'D:\')) {
    Write-Host "Le lecteur D: est introuvable."
    $dest = Read-Host 'Entrez un autre dossier d''installation (ex. C:\Clavier-6T)'
    if ([string]::IsNullOrWhiteSpace($dest)) { Write-Host 'Annule.'; exit 1 }
}
Write-Host "Installation dans : $dest"
if (Test-Path -LiteralPath $dest) {
    $a = Read-Host 'Ce dossier existe deja : le mettre a jour (les fichiers du meme nom seront remplaces) ? (O/N)'
    if ($a -notmatch '^[oOyY]') { Write-Host 'Annule.'; exit 0 }
}

$tmp = Join-Path $env:TEMP ('clavier-install-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
$src = $null
foreach ($ref in $refs) {
    try {
        $zip = Join-Path $tmp 'repo.zip'
        Write-Host "Telechargement ($ref) ..."
        Invoke-WebRequest -Uri "https://github.com/$repo/archive/refs/$ref.zip" -OutFile $zip -UseBasicParsing -Headers $ua
        $ex = Join-Path $tmp ('x-' + [guid]::NewGuid().ToString('N'))
        Expand-Archive -LiteralPath $zip -DestinationPath $ex -Force
        $root = Get-ChildItem -LiteralPath $ex -Directory | Select-Object -First 1
        $cand = Join-Path $root.FullName 'clavier'
        if (Test-Path -LiteralPath (Join-Path $cand 'windows\Clavier.bat')) { $src = $cand; break }
        Write-Host '  Cette version ne contient pas encore les lanceurs, essai suivant ...'
    } catch { Write-Host "  Echec : $($_.Exception.Message)" }
}
if (-not $src) { Write-Host 'Impossible de recuperer l''appli. Verifiez votre connexion.'; Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue; exit 1 }

New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -Path (Join-Path $src '*') -Destination $dest -Recurse -Force
Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Fichiers copies dans $dest"

$launcher = Join-Path $dest 'windows\Clavier.bat'
$a = Read-Host 'Creer un raccourci "Clavier 6T" sur le bureau ? (O/N)'
if ($a -match '^[oOyY]') {
    try {
        $desktop = [Environment]::GetFolderPath('Desktop')
        $sh = New-Object -ComObject WScript.Shell
        $lnk = $sh.CreateShortcut((Join-Path $desktop 'Clavier 6T.lnk'))
        $lnk.TargetPath = $launcher
        $lnk.WorkingDirectory = Join-Path $dest 'windows'
        $lnk.Description = 'Configuration du clavier 6 touches + potentiometre'
        $lnk.Save()
        Write-Host 'Raccourci cree sur le bureau.'
    } catch { Write-Host "Raccourci non cree : $($_.Exception.Message)" }
}
Write-Host ''
Write-Host "Termine. Lancez : $launcher"
$a = Read-Host 'Lancer l''appli maintenant ? (O/N)'
if ($a -match '^[oOyY]') { Start-Process -FilePath $launcher -WorkingDirectory (Join-Path $dest 'windows') }
exit 0
