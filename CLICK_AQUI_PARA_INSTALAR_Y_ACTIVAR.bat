@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM CONFIGURACION
REM ============================================================
set "RUTA_SETUP=%~dp0"
set "CONFIGXML=%RUTA_SETUP%configuration.xml"
set "WORD_PATH=C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE"
set "WORD_PATH_X86=C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE"

REM Verificar si se esta ejecutando como administrador
call :VerificarAdmin

REM Desinstalar versiones de Office
call :DesinstalarOffice

REM Instalar Office y ESPERAR a que termine
call :InstalarOffice

REM Activar Office SOLO DESPUES de que la instalacion termino
call :ActivarOffice

REM Finalizar
call :Finalizar
exit /b

REM ============================================================
REM VERIFICAR ADMINISTRADOR
REM ============================================================
:VerificarAdmin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ADMIN] Requiere privilegios elevados. Relanzando...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
echo [OK] Ejecutando como administrador
exit /b

REM ============================================================
REM DESINSTALAR OFFICE
REM ============================================================
:DesinstalarOffice
echo.
echo ============================================
echo DESINSTALANDO VERSIONES ANTERIORES
echo ============================================
powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Continue'; $apps=@('Microsoft 365 - en-us','Microsoft 365 - es-es','Microsoft 365 - fr-fr','Microsoft 365 - pt-br','Microsoft OneNote - en-us','Microsoft OneNote - es-es','Microsoft OneNote - fr-fr','Microsoft OneNote - pt-br'); foreach($a in $apps){ winget uninstall --name \"$a\" --exact --silent --accept-source-agreements --disable-interactivity 2>$null }"
echo [OK] Desinstalacion completada
timeout /t 2 /nobreak >nul
exit /b

REM ============================================================
REM INSTALAR OFFICE - ESPERAR A QUE TERMINE
REM ============================================================
:InstalarOffice
echo.
echo ============================================
echo INSTALANDO MICROSOFT OFFICE
echo ============================================

REM Desbloquear setup.exe
powershell -WindowStyle Hidden -NoProfile -Command "Unblock-File -Path '%RUTA_SETUP%setup.exe' -ErrorAction SilentlyContinue" >nul 2>&1

REM Verificar archivos
if not exist "%RUTA_SETUP%setup.exe" (
    echo [X] setup.exe no encontrado en %RUTA_SETUP%
    timeout /t 5 /nobreak >nul
    exit /b 1
)
if not exist "%CONFIGXML%" (
    echo [X] configuration.xml no encontrado
    timeout /t 5 /nobreak >nul
    exit /b 1
)

echo [OK] Archivos verificados
echo [INFO] Iniciando instalacion silenciosa...
echo [INFO] Esto puede tardar varios minutos. Por favor espere...

REM Ejecutar setup.exe y ESPERAR (-Wait) a que termine
powershell -WindowStyle Hidden -NoProfile -Command ^
"$proc = Start-Process -FilePath '%RUTA_SETUP%setup.exe' -ArgumentList '/configure','%CONFIGXML%' -NoNewWindow -Wait -PassThru; ^
if ($proc.ExitCode -ne 0) { Write-Host ('[X] Error en instalacion. Codigo: ' + $proc.ExitCode); exit 1 } else { Write-Host '[OK] Instalacion completada exitosamente' }"

if %errorlevel% neq 0 (
    echo [X] La instalacion fallo. Abortando.
    timeout /t 5 /nobreak >nul
    exit /b 1
)

echo [OK] Instalacion finalizada correctamente
timeout /t 3 /nobreak >nul
exit /b

REM ============================================================
REM ACTIVAR OFFICE - DESPUES DE INSTALACION COMPLETA
REM ============================================================
:ActivarOffice
echo.
echo ============================================
echo ACTIVANDO MICROSOFT OFFICE
echo ============================================

echo [INFO] Descargando e iniciando Microsoft Activation Script 3.11...

REM Ejecutar MAS en una ventana visible pero minimizada para poder enviar teclas
REM -WindowStyle Minimized permite que tenga ventana para recibir teclas
start /min powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$url = 'https://get.activated.win'; ^
try { ^
    $script = irm $url -ErrorAction Stop; ^
    Write-Host '[OK] Script descargado. Ejecutando...'; ^
    iex $script; ^
} catch { ^
    Write-Host ('[X] Error al descargar: ' + $_.Exception.Message); ^
    Read-Host 'Presione Enter para salir'; ^
    exit 1; ^
}"

echo [INFO] Esperando 25 segundos para que cargue la interfaz...
timeout /t 25 /nobreak >nul

REM CORRECCION: Enviar teclas con busqueda por titulo exacto
call :EnviarTeclas
exit /b

REM ============================================================
REM ENVIAR TECLAS AUTOMATICAMENTE - CORREGIDO PARA MAS 3.11
REM ============================================================
:EnviarTeclas
set "max_intentos=60"
set "intento=0"

:buscar_ventana
set /a intento+=1
echo [%intento%/%max_intentos%] Buscando ventana de activacion...

REM CORRECCION CRITICA:
REM 1. Buscar por titulo que contenga "Microsoft Activation Scripts"
REM 2. Usar AppActivate con el TITULO de ventana (mas confiable)
REM 3. Secuencia: 2 (Ohook) -> 1 (Install)
REM 4. Tiempos de espera aumentados para ventanas CMD
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"Add-Type -AssemblyName System.Windows.Forms; ^
$wshell = New-Object -ComObject WScript.Shell; ^
$found = $false; ^
$maxWait = 60; ^
for ($i = 0; $i -lt $maxWait; $i++) { ^
    $procs = Get-Process | Where-Object { $_.MainWindowTitle -match 'Microsoft Activation Scripts|MAS.*3\.11|Ohook' }; ^
    foreach ($p in $procs) { ^
        if ($p.MainWindowHandle -ne 0) { ^
            $title = $p.MainWindowTitle; ^
            Write-Host ('Encontrada ventana: ' + $title); ^
            Start-Sleep -Milliseconds 500; ^
            $result = $wshell.AppActivate($title); ^
            if ($result) { ^
                Write-Host '[OK] Ventana activada'; ^
                Start-Sleep -Milliseconds 2000; ^
                $wshell.SendKeys('2'); ^
                Write-Host '[OK] Enviado: 2 (Ohook)'; ^
                Start-Sleep -Milliseconds 3000; ^
                $wshell.SendKeys('1'); ^
                Write-Host '[OK] Enviado: 1 (Install)'; ^
                Start-Sleep -Milliseconds 2000; ^
                $found = $true; ^
                break; ^
            } else { ^
                Write-Host '[!] No se pudo activar la ventana, intentando con handle...'; ^
                $wshell.AppActivate($p.MainWindowHandle); ^
                Start-Sleep -Milliseconds 2000; ^
                $wshell.SendKeys('2'); ^
                Start-Sleep -Milliseconds 3000; ^
                $wshell.SendKeys('1'); ^
                $found = $true; ^
                break; ^
            } ^
        } ^
    } ^
    if ($found) { break } ^
    Start-Sleep -Milliseconds 1000; ^
}; ^
if ($found) { exit 0 } else { exit 1 }"

if %errorlevel% equ 0 (
    echo.
    echo [OK] Teclas enviadas correctamente: 2 (Ohook), 1 (Install)
    echo [INFO] Esperando 20 segundos para completar activacion...
    timeout /t 20 /nobreak >nul
    exit /b 0
)

if %intento% geq %max_intentos% (
    echo.
    echo [!] Ventana no encontrada despues de %max_intentos% intentos.
    echo [INFO] Posiblemente el activador no se inicio o cambio de interfaz.
    timeout /t 5 /nobreak >nul
    exit /b 0
)

timeout /t 2 /nobreak >nul
goto buscar_ventana

REM ============================================================
REM FINALIZAR
REM ============================================================
:Finalizar
echo.
echo ============================================
echo PROCESO COMPLETADO
echo ============================================
echo [OK] Proceso finalizado.
echo.
echo Cerrando en 10 segundos...
timeout /t 10 /nobreak >nul
exit