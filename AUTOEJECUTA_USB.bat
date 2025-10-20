
@echo off
REM Script para ejecutar automáticamente al conectar el USB
REM Menú interactivo para elegir qué instalar

:menu
cls
echo =============================================
echo   Instalador General - Seleccione una opcion
echo =============================================
echo 1. Instalacion General (todo)
echo 2. Instalar solo psqlodbc_x64.msi
echo 3. Ejecutar solo Cargue Masivo WPF
echo 4. Ejecutar solo instalador y activador de Office
echo 5. Salir
set /p opcion=Ingrese el numero de la opcion deseada: 

if "%opcion%"=="1" goto instalar_todo
if "%opcion%"=="2" goto instalar_odbc
if "%opcion%"=="3" goto ejecutar_cargue
if "%opcion%"=="4" goto ejecutar_office
if "%opcion%"=="5" goto fin
echo Opcion invalida. Intente de nuevo.
timeout /t 2 >nul
goto menu

:instalar_todo
call "%~f0" todo
goto fin

:instalar_odbc
REM Instalar psqlodbc_x64.msi si existe
if exist "D:\psqlodbc_x64.msi" (
    echo Instalando psqlodbc_x64.msi...
    msiexec /i "D:\psqlodbc_x64.msi" /qn /norestart
    echo Instalacion de psqlodbc_x64.msi completada.
) else (
    echo No se encontro D:\psqlodbc_x64.msi
)
goto fin

:ejecutar_cargue
REM Ejecutar la aplicacion ClickOnce si existe
if exist "D:\Cargue Masivo WPF - copia (4).appref-ms" (
    echo Ejecutando Cargue Masivo WPF - copia (4)...
    start "" "D:\Cargue Masivo WPF - copia (4).appref-ms"
) else (
    echo No se encontro D:\Cargue Masivo WPF - copia (4).appref-ms
)
goto fin

:ejecutar_office
REM Ejecutar el script de instalacion y activacion de Office si existe
if exist "D:\ACTIVACION_OFICE\CLICK_AQUI_PARA_INSTALAR_Y_ACTIVAR.bat" (
    echo Ejecutando instalador y activador de Office...
    start "" "D:\ACTIVACION_OFICE\CLICK_AQUI_PARA_INSTALAR_Y_ACTIVAR.bat"
) else (
    echo No se encontro CLICK_AQUI_PARA_INSTALAR_Y_ACTIVAR.bat
)
goto fin

:todo
REM Instalar psqlodbc_x64.msi si existe
if exist "D:\psqlodbc_x64.msi" (
    echo Instalando psqlodbc_x64.msi...
    msiexec /i "D:\psqlodbc_x64.msi" /qn /norestart
    echo Instalacion de psqlodbc_x64.msi completada.
) else (
    echo No se encontro D:\psqlodbc_x64.msi
)

REM Ejecutar la aplicacion ClickOnce si existe
if exist "D:\Cargue Masivo WPF - copia (4).appref-ms" (
    echo Ejecutando Cargue Masivo WPF - copia (4)...
    start "" "D:\Cargue Masivo WPF - copia (4).appref-ms"
) else (
    echo No se encontro D:\Cargue Masivo WPF - copia (4).appref-ms
)

REM Ejecutar el script de instalacion y activacion de Office si existe
if exist "D:\ACTIVACION_OFICE\CLICK_AQUI_PARA_INSTALAR_Y_ACTIVAR.bat" (
    echo Ejecutando instalador y activador de Office...
    start "" "D:\ACTIVACION_OFICE\CLICK_AQUI_PARA_INSTALAR_Y_ACTIVAR.bat"
) else (
    echo No se encontro CLICK_AQUI_PARA_INSTALAR_Y_ACTIVAR.bat
)
goto fin

:fin
echo.
echo Proceso finalizado. Puede cerrar esta ventana.
timeout /t 2 >nul
exit /b
