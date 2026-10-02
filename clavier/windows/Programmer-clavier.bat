@echo off
rem Envoie la configuration au clavier avec l'outil officiel ch57x-keyboard-tool.
rem Dossier : placez ici ch57x-keyboard-tool.exe et votre fichier mapping.yaml
rem (exporte depuis l'appli avec le bouton "Exporter (outil ch57x)").
cd /d "%~dp0"
set "CFG=mapping.yaml"
if not exist "%CFG%" set "CFG=mapping-8890.yaml"
if not exist ch57x-keyboard-tool.exe (
  echo ch57x-keyboard-tool.exe est introuvable dans ce dossier.
  echo Telechargez-le sur https://github.com/kriomant/ch57x-keyboard-tool/releases
  echo et installez USBDK : https://github.com/daynix/UsbDk/releases
  pause
  exit /b 1
)
if not exist "%CFG%" (
  echo Aucun fichier de configuration : mettez mapping.yaml dans ce dossier.
  pause
  exit /b 1
)
echo Verification de %CFG% ...
ch57x-keyboard-tool.exe validate "%CFG%"
if errorlevel 1 (
  echo La configuration est invalide. Rien n'a ete envoye au clavier.
  pause
  exit /b 1
)
echo Envoi au clavier ...
ch57x-keyboard-tool.exe upload "%CFG%"
if errorlevel 1 (
  echo Echec de l'envoi. Verifiez que le clavier est branche et que USBDK est installe.
  pause
  exit /b 1
)
echo Termine : le clavier est programme.
pause
