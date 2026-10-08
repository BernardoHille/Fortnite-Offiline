[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$lock = Get-Content -LiteralPath (Join-Path $root 'configs/stack.lock.json') -Raw | ConvertFrom-Json
foreach($kind in @('gameserver','backend')){
    $entry=$lock.$kind
    $destination=Join-Path $root "$kind/vendor/$($entry.name)"
    if(-not (Test-Path -LiteralPath (Join-Path $destination '.git'))){
        if(Test-Path -LiteralPath $destination){throw "Existing destination is not a Git checkout: $destination"}
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        git init $destination
        if($LASTEXITCODE -ne 0){throw 'git init failed'}
        git -C $destination remote add origin $entry.url
        if($LASTEXITCODE -ne 0){throw 'git remote failed'}
        git -C $destination fetch --depth 1 origin $entry.commit
        if($LASTEXITCODE -ne 0){throw 'Pinned upstream commit could not be fetched'}
        git -C $destination checkout -b $entry.branch FETCH_HEAD
        if($LASTEXITCODE -ne 0){throw 'git checkout failed'}
    }
    $head=git -C $destination rev-parse HEAD
    if($head -ne $entry.commit){throw "Unexpected upstream commit in $kind; existing checkout was preserved."}
    if($kind -eq 'backend'){
        foreach($relativePatch in $entry.patches){
            $patch=Join-Path $root $relativePatch
            git -C $destination apply --check $patch 2>$null
            if($LASTEXITCODE -eq 0){git -C $destination apply $patch; if($LASTEXITCODE -ne 0){throw 'Patch application failed'}}else{
                git -C $destination apply --reverse --check $patch 2>$null
                if($LASTEXITCODE -ne 0){throw "Patch conflicts with current files: $relativePatch"}
            }
        }
        Push-Location -LiteralPath $destination
        try{npm ci --ignore-scripts --no-audit --no-fund; if($LASTEXITCODE -ne 0){throw 'npm ci failed'}}finally{Pop-Location}
    }
}
Write-Output '[OK] Two pinned source checkouts restored. No game binaries were downloaded or run.'
