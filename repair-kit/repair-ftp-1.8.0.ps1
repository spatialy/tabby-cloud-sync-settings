# Repairs the closed-FTP-client checks in cloud-settings-sync 1.8.0.
# Close Tabby before running. No credentials or network access are needed.
& {
    $ErrorActionPreference = 'Stop'

    if (Get-Process -Name Tabby -ErrorAction SilentlyContinue) {
        throw 'Close Tabby completely, then run this again.'
    }

    $pluginDir = Join-Path $env:APPDATA 'tabby\plugins\node_modules\terminus-cloud-settings-sync'
    $pluginFile = Join-Path $pluginDir 'dist\index.js'
    $pluginInfo = Get-Content -LiteralPath (Join-Path $pluginDir 'package.json') -Raw | ConvertFrom-Json

    if ($pluginInfo.version -ne '1.8.0') {
        throw "Unexpected version: $($pluginInfo.version). No changes made."
    }

    $pluginCode = [IO.File]::ReadAllText($pluginFile)
    $fixPattern = [regex]'if\s*\(\s*!this\.ftpClient\s*\)'
    $fixedGuard = 'if (!this.ftpClient || this.ftpClient.closed)'

    if ($fixPattern.Matches($pluginCode).Count -eq 0 -and
        ([regex]::Matches($pluginCode, [regex]::Escape($fixedGuard))).Count -eq 2) {
        Write-Host 'Both FTP reconnect checks are already fixed. No changes made.'
        return
    }

    if ($fixPattern.Matches($pluginCode).Count -ne 2) {
        throw 'The installed code differs from the expected version. No changes made.'
    }

    $repairId = [guid]::NewGuid().ToString('N')
    $backupFile = "$pluginFile.before-ftp-fix-$repairId.bak"
    $fixedCode = $fixPattern.Replace($pluginCode, $fixedGuard)
    $temporaryFile = "$pluginFile.$repairId.tmp"
    [IO.File]::WriteAllText($temporaryFile, $fixedCode, [Text.UTF8Encoding]::new($false))
    [IO.File]::Replace($temporaryFile, $pluginFile, $backupFile)

    Write-Host 'Repair applied. Reopen Tabby and retry Test connection, then Save.'
    Write-Host "Original plugin backup: $backupFile"
}
