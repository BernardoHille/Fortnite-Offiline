#Requires -Version 5.1
# Double-click bootstrap for the BAT. All firewall operations stay in the existing PS7 scripts.
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [ValidateSet('Prepare', 'Cleanup')] [string]$Action,
    [switch]$Elevated
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$handedOff = $false
$resultCode = 1

function Find-RuntimeObservationPowerShell7 {
    $candidates = @()
    $command = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($command) { $candidates += $command.Source }
    $candidates += @(
        (Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\PowerShell\7\pwsh.exe'),
        (Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\native\powershell\pwsh.exe')
    )
    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        $versionText = (Get-Item -LiteralPath $candidate).VersionInfo.ProductVersion
        if ($versionText -match '^(\d+\.\d+\.\d+)') {
            if ([version]$Matches[1] -ge [version]'7.4.0') { return $candidate }
        }
    }
    throw 'PowerShell 7.4+ nao encontrado. Nenhum programa foi instalado e nenhuma regra foi aplicada.'
}

try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $administrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($Elevated -and -not $administrator) { throw 'A janela nao recebeu privilegio de administrador. Operacao cancelada.' }

    if (-not $administrator -or $PSVersionTable.PSVersion -lt [version]'7.4.0') {
        $pwsh = Find-RuntimeObservationPowerShell7
        # -File passes a literal script path, not interpolated PowerShell code.
        $arguments = @('-NoProfile', '-File', ('"' + $PSCommandPath + '"'), '-Action', $Action, '-Elevated')
        $startOptions = @{
            FilePath = $pwsh; ArgumentList = $arguments; WorkingDirectory = $projectRoot
            WindowStyle = 'Normal'; Wait = $true; PassThru = $true
        }
        if (-not $administrator) {
            Write-Host 'O Windows solicitara permissao de administrador para esta operacao.'
            $startOptions.Verb = 'RunAs'
        }
        $child = Start-Process @startOptions
        $handedOff = $true
        $resultCode = $child.ExitCode
    } else {
        Set-Location -LiteralPath $projectRoot
        $scriptName = if ($Action -eq 'Prepare') { 'prepare-phase2-runtime-observation.ps1' } else { 'cleanup-phase2-runtime-observation.ps1' }
        $targetScript = Join-Path $PSScriptRoot $scriptName
        Write-Host "Operacao: $Action" -ForegroundColor Cyan
        Write-Host 'Nenhum cliente, captura ou gameserver sera iniciado.'
        & $targetScript -Apply
        $resultCode = 0
        if ($Action -eq 'Prepare') {
            Write-Host 'Preparacao terminou. Confira o resultado acima; a captura filtrada ainda precisa ser verificada.' -ForegroundColor Green
            Write-Host 'Mantenha a rede desconectada. Este atalho nao autoriza nem abre o cliente.'
        } else {
            Write-Host 'Cleanup terminou. Confira a confirmacao de remocao e comparacao de politica acima.' -ForegroundColor Green
        }
    }
} catch {
    Write-Host ('FALHA: ' + $_.Exception.Message) -ForegroundColor Red
    try {
        $diagnosticDirectory = Join-Path $projectRoot 'logs'
        New-Item -ItemType Directory -Path $diagnosticDirectory -Force | Out-Null
        [ordered]@{
            TimestampUtc = [DateTime]::UtcNow.ToString('o'); Action = $Action
            ExceptionType = $_.Exception.GetType().FullName; Message = $_.Exception.Message
            ScriptStackTrace = $_.ScriptStackTrace; ScriptName = $_.InvocationInfo.ScriptName
            ScriptLineNumber = $_.InvocationInfo.ScriptLineNumber
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $diagnosticDirectory 'phase2-runtime-last-error.json') -Encoding utf8
        Write-Host 'Diagnostico salvo em logs/phase2-runtime-last-error.json (privado).'
    } catch { Write-Warning 'Nao foi possivel salvar o diagnostico; copie a mensagem visivel.' }
    Write-Host 'Nao abra Fortnite. Se a preparacao foi interrompida, preserve a rede desconectada e confira o cleanup.'
    $resultCode = 1
} finally {
    if (-not $handedOff) { $null = Read-Host 'Pressione Enter para fechar esta janela' }
}
exit $resultCode
