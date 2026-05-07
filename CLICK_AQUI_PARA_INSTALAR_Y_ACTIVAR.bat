@echo off
REM Verificar si se está ejecutando como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Este script requiere privilegios de administrador.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

REM Desinstalar versiones de Office detectadas
echo Buscando instalaciones de Office para desinstalar...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Continue'; $apps = @('Microsoft 365 - en-us', 'Microsoft 365 - es-es', 'Microsoft 365 - fr-fr', 'Microsoft 365 - pt-br', 'Microsoft OneNote - en-us', 'Microsoft OneNote - es-es', 'Microsoft OneNote - fr-fr', 'Microsoft OneNote - pt-br'); foreach ($a in $apps) { Write-Host \"==> Desinstalando: $a\" -ForegroundColor Cyan; winget uninstall --name \"$a\" --exact --silent --accept-source-agreements --disable-interactivity }"

REM Usar la ruta del script como ruta base
SET BASE_PATH=%~dp0
set "encontrado="

REM Verificar si existe setup.exe en la ruta base
if exist "%BASE_PATH%\setup.exe" (
    set "encontrado=%BASE_PATH%"
    echo Se encontró setup.exe en la ruta del script: %BASE_PATH%
    goto instalar_office
)

REM Si no se encontró, pedir ruta al usuario
:pedir_ruta
echo No se encontró setup.exe en la ruta del script.
set /p ruta=Ingresa la ruta donde se encuentra el archivo setup.exe: 
if "%ruta%"=="" (
    echo No se especificó una ruta. Abortando.
    goto fin
)
if exist "%ruta%\setup.exe" (
    set "encontrado=%ruta%"
    echo Se encontró setup.exe en: %encontrado%
    goto instalar_office
) else (
    echo La ruta especificada no es válida o no contiene setup.exe.
    goto pedir_ruta
)

:instalar_office
cd /d "%encontrado%"
echo Usando la ruta: %encontrado%
set "configxml=%encontrado%\configuration.xml"
echo Usando archivo de configuración: %configxml%

if not exist "%configxml%" (
    echo No se encontró el archivo configuration.xml en la ruta especificada.
    set /p configxml=Ingresa la ruta correcta donde se encuentra el archivo configuration.xml: 
    if not exist "%configxml%" (
        echo No se pudo encontrar el archivo configuration.xml. Abortando instalación.
        goto fin
    )
)

echo Iniciando instalación de Office...
setup /configure "%configxml%"
if errorlevel 1 (
    echo Error al ejecutar setup.exe. Verifica el archivo configuration.xml.
    pause
    goto fin
)

echo Instalación completada. Iniciando proceso de activación...

:activar_office
REM Iniciar el script de PowerShell para la activación en un subproceso
echo Iniciando script de activación...
start /b powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"

REM Esperar más tiempo para que la ventana se cargue completamente
echo Esperando 10 segundos para que se cargue la ventana de activación...
timeout /t 10 >nul

REM Proceso mejorado para buscar la ventana y simular teclas
set "ventana=Microsoft Activation Script 3.10"
set "max_intentos=30"
set "intento=0"
:buscar_ventana_mejorada
set /a intento+=1
echo Intentando encontrar la ventana "%ventana%"... (Intento %intento% de %max_intentos%)

REM Usar un método más robusto para encontrar y activar la ventana
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Window { [DllImport(\"user32.dll\")] public static extern IntPtr FindWindow(string lpClassName, string lpWindowName); [DllImport(\"user32.dll\")] public static extern bool SetForegroundWindow(IntPtr hWnd); }'; $hwnd = [Window]::FindWindow([String]::Empty, '%ventana%'); if ($hwnd -ne [IntPtr]::Zero) { [Window]::SetForegroundWindow($hwnd); Start-Sleep -Milliseconds 1000; $wshell = New-Object -ComObject WScript.Shell; $wshell.SendKeys('2'); Start-Sleep -Milliseconds 1500; $wshell.SendKeys('1'); exit 0; } else { exit 1; }"

if %errorlevel% neq 0 (
    if %intento% geq %max_intentos% (
        echo No se pudo encontrar la ventana "%ventana%" tras %max_intentos% intentos.
        echo Por favor, seleccione manualmente la ventana y presione 2, luego 1.
        pause
        goto fin
    )
    echo La ventana no se encontró. Esperando 2 segundos antes del próximo intento...
    timeout /t 2 >nul
    goto buscar_ventana_mejorada
)

echo Se enviaron las teclas 2 y 1 a la ventana de activación.
echo Proceso de activación iniciado. La ventana se cerrará automáticamente cuando termine.
timeout /t 5 >nul

:fin
echo Proceso completado. Esta ventana se cerrará automáticamente en 5 segundos.
timeout /t 5 >nul
exit 