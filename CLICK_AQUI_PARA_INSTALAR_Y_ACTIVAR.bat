@echo off
REM Verificar si se está ejecutando como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Este script requiere privilegios de administrador.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

REM Definir las rutas a intentar
 REM Todas las rutas han sido actualizadas para usar D:\ACTIVACION_OFICE
 SET BASE_PATH=D:\ACTIVACION_OFICE
 REM Ejemplo de uso: %BASE_PATH%\archivo.ext
 REM Reemplaza las rutas anteriores por %BASE_PATH%\...
 set "ruta1=%BASE_PATH%"
 set "ruta2=%BASE_PATH%"
 set "ruta3=%BASE_PATH%"

REM Validar rutas una por una y ejecutar setup.exe
set "encontrado="
for %%R in ("%ruta1%" "%ruta2%" "%ruta3%") do (
    if exist %%R\setup.exe (
        set "encontrado=%%R"
        cd /d "%%R"
        set /p configxml=Ingresa la ruta donde se encuentra el archivo configuration.xml:
        setup /configure "%configxml%"
        if errorlevel 1 (
            echo Error al ejecutar setup.exe en %%R. Verifica el archivo configuration.xml.
        ) else (
            goto activar_office
        )
    )
)

REM Si no se encontró o falló, pedir ruta al usuario
:pedir_ruta
set /p ruta=No se encontró setup.exe o hubo error. Ingresa la ruta donde se encuentra el archivo setup.exe o intente dando enter:
if exist "%ruta%\setup.exe" (
    cd /d "%ruta%"
    set /p configxml=Ingresa la ruta donde se encuentra el archivo configuration.xml o intente de nuevo dando enter:
    setup /configure "%configxml%"
    if errorlevel 1 (
        echo Error al ejecutar setup.exe. Verifica el archivo configuration.xml.
        goto pedir_ruta
    ) else (
        goto activar_office
    )
) else (
    echo La ruta especificada no es válida.
    goto pedir_ruta
)

:activar_office
REM Iniciar el script de PowerShell para la activación en un subproceso
start /b powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"

REM Esperar 7 segundos para buscar ventana, seleccionarla y ejecutar las teclas
echo Esperando 7 segundos para buscar la ventana de Microsoft Enable Script 3.5...
timeout /t 7 >nul


REM Mejor proceso para buscar la ventana y simular teclas
set "ventana=Microsoft Enable Script 3.5"
set "max_intentos=20"
set "intento=0"
:buscar_ventana_mejorada
set /a intento+=1
powershell -NoProfile -ExecutionPolicy Bypass -Command "
$wshell = New-Object -ComObject WScript.Shell;
$found = $false;
for ($i=0; $i -lt 3; $i++) {
    if ($wshell.AppActivate('%ventana%')) {
        $found = $true; break;
    } else {
        Start-Sleep -Milliseconds 700
    }
}
if (-not $found) { exit 1 } else { exit 0 }
"
if %errorlevel% neq 0 (
    if %intento% geq %max_intentos% (
        echo No se pudo encontrar la ventana "%ventana%" tras %max_intentos% intentos.
        goto fin
    )
    echo Esperando a que aparezca la ventana "%ventana%"... (Intento %intento% de %max_intentos%)
    timeout /t 2 >nul
    goto buscar_ventana_mejorada
)

REM Simular la entrada de teclas 2 y 1 de forma más robusta
powershell -NoProfile -ExecutionPolicy Bypass -Command "
$wshell = New-Object -ComObject WScript.Shell;
if ($wshell.AppActivate('%ventana%')) {
    Start-Sleep -Milliseconds 500;
    $wshell.SendKeys('2');
    Start-Sleep -Milliseconds 800;
    $wshell.SendKeys('1');
} else {
    Write-Host 'No se pudo activar la ventana para enviar teclas.'
}"

REM Mensaje final
echo Ya puedes cerrar esta ventana. Windows activado.
pause