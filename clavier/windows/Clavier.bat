@echo off
rem Ouvre l'appli Clavier dans une fenetre dediee (Chrome ou Edge), sans barre d'adresse.
set "URL=https://letyvandm-glitch.github.io/clavier/"
set "CHROME1=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
set "CHROME2=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
set "CHROME3=%LocalAppData%\Google\Chrome\Application\chrome.exe"
set "EDGE=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if exist "%CHROME1%" ( start "" "%CHROME1%" --app=%URL% & exit /b 0 )
if exist "%CHROME2%" ( start "" "%CHROME2%" --app=%URL% & exit /b 0 )
if exist "%CHROME3%" ( start "" "%CHROME3%" --app=%URL% & exit /b 0 )
if exist "%EDGE%" ( start "" "%EDGE%" --app=%URL% & exit /b 0 )
echo Chrome ou Edge est introuvable : ouverture dans le navigateur par defaut.
echo (WebHID ne fonctionne que dans Chrome ou Edge.)
start "" "%URL%"
pause
