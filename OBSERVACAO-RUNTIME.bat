@echo off
setlocal DisableDelayedExpansion
title Fortnite-Local-C2S3 - Observacao de runtime
echo.
echo Fortnite-Local-C2S3 - Observacao de runtime
echo.
echo 1 - PREPARAR: execute depois de desconectar toda rede externa.
echo 2 - LIMPAR: execute depois de fechar o cliente e seus auxiliares.
echo 0 - SAIR
echo.
echo Este atalho nao abre Fortnite, Procmon ou gameserver.
echo Nao altera adaptadores, DNS ou a politica de execucao do PowerShell.
echo.
choice /C 120 /N /M "Escolha [1/2/0]: "
if errorlevel 255 goto falha
if errorlevel 3 exit /b 0
if errorlevel 2 goto limpar
if errorlevel 1 goto preparar
goto falha

:preparar
set "FN_RUNTIME_ACTION=Prepare"
goto executar

:limpar
set "FN_RUNTIME_ACTION=Cleanup"
goto executar

:executar
rem Use PowerShell 7 directly; Windows PowerShell 5.1 may prohibit local scripts.
rem No execution-policy override is used.
set "FN_RUNTIME_PWSH="
if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" set "FN_RUNTIME_PWSH=%ProgramFiles%\PowerShell\7\pwsh.exe"
if not defined FN_RUNTIME_PWSH if exist "%LOCALAPPDATA%\Programs\PowerShell\7\pwsh.exe" set "FN_RUNTIME_PWSH=%LOCALAPPDATA%\Programs\PowerShell\7\pwsh.exe"
if not defined FN_RUNTIME_PWSH if exist "%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\powershell\pwsh.exe" set "FN_RUNTIME_PWSH=%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\powershell\pwsh.exe"
if not defined FN_RUNTIME_PWSH for /f "delims=" %%P in ('where.exe pwsh.exe 2^>nul') do if not defined FN_RUNTIME_PWSH set "FN_RUNTIME_PWSH=%%P"
if not defined FN_RUNTIME_PWSH goto sem_powershell7
"%FN_RUNTIME_PWSH%" -NoProfile -File "%~dp0scripts\invoke-phase2-runtime-observation.ps1" -Action %FN_RUNTIME_ACTION%
set "FN_RUNTIME_RESULT=%errorlevel%"
echo.
echo Codigo de saida: %FN_RUNTIME_RESULT%
echo Se houve erro, nao abra Fortnite. Esta janela permanece aberta para leitura.
pause
exit /b %FN_RUNTIME_RESULT%

:sem_powershell7
echo PowerShell 7 nao encontrado. Nenhuma regra foi criada ou removida.
pause
exit /b 1

:falha
echo Nao foi possivel ler a opcao. Nenhum script de isolamento foi iniciado.
pause
exit /b 1
