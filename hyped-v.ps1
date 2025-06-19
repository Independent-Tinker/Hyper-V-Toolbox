Write-Host @"
┏┓━┏┓━━━━━━━━━━━━━━━━━━━━━┏┓━━┏┓━━━━━┏━━━━┓━━━━━━━━┏┓━┏┓━━━━━━━━━━
┃┃━┃┃━━━━━━━━━━━━━━━━━━━━━┃┗┓┏┛┃━━━━━┃┏┓┏┓┃━━━━━━━━┃┃━┃┃━━━━━━━━━━
┃┗━┛┃┏┓━┏┓┏━━┓┏━━┓┏━┓━━━━━┗┓┃┃┏┛━━━━━┗┛┃┃┗┛┏━━┓┏━━┓┃┃━┃┗━┓┏━━┓┏┓┏┓
┃┏━┓┃┃┃━┃┃┃┏┓┃┃┏┓┃┃┏┛┏━━━┓━┃┗┛┃━┏━━━┓━━┃┃━━┃┏┓┃┃┏┓┃┃┃━┃┏┓┃┃┏┓┃┗╋╋┛
┃┃━┃┃┃┗━┛┃┃┗┛┃┃┃━┫┃┃━┗━━━┛━┗┓┏┛━┗━━━┛━┏┛┗┓━┃┗┛┃┃┗┛┃┃┗┓┃┗┛┃┃┗┛┃┏╋╋┓
┗┛━┗┛┗━┓┏┛┃┏━┛┗━━┛┗┛━━━━━━━━┗┛━━━━━━━━┗━━┛━┗━━┛┗━━┛┗━┛┗━━┛┗━━┛┗┛┗┛
━━━━━┏━┛┃━┃┃━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
━━━━━┗━━┛━┗┛━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"@ -ForegroundColor Cyan


# Check for host-tools and client-tools directories
$hostToolsPath = Join-Path -Path (Get-Location) -ChildPath "host-tools"
$clientToolsPath = Join-Path -Path (Get-Location) -ChildPath "client-tools"

$hostPs1Files = @()
$clientPs1Files = @()

if (Test-Path -Path $hostToolsPath -PathType Container) {
    $hostPs1Files = Get-ChildItem -Path $hostToolsPath -Filter *.ps1 | Sort-Object Name
}
if (Test-Path -Path $clientToolsPath -PathType Container) {
    $clientPs1Files = Get-ChildItem -Path $clientToolsPath -Filter *.ps1 | Sort-Object Name
}

if ($hostPs1Files.Count -eq 0 -and $clientPs1Files.Count -eq 0) {
    Write-Host "No .ps1 files found in host-tools or client-tools directories." -ForegroundColor Yellow
    exit
}

do {
    $toolChoice = $null

    if ($hostPs1Files.Count -gt 0 -and $clientPs1Files.Count -gt 0) {
        Write-Host "`nSelect a toolbox:" -ForegroundColor Cyan
        Write-Host ("=" * 39)
        Write-Host "1. host-tools"
        Write-Host "2. client-tools"
        Write-Host "0. Exit" -ForegroundColor Yellow
        Write-Host "`nEnter your choice: " -NoNewline -ForegroundColor Cyan
        $toolChoice = Read-Host

        if ($toolChoice -eq '0') {
            Write-Host "Exiting..." -ForegroundColor Green
            break
        } elseif ($toolChoice -eq '1') {
            $ps1Files = $hostPs1Files
            $toolName = "host-tools"
        } elseif ($toolChoice -eq '2') {
            $ps1Files = $clientPs1Files
            $toolName = "client-tools"
        } else {
            Write-Host "`nInvalid selection. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
            continue
        }
    } elseif ($hostPs1Files.Count -gt 0) {
        $ps1Files = $hostPs1Files
        $toolName = "host-tools"
    } else {
        $ps1Files = $clientPs1Files
        $toolName = "client-tools"
    }

    # List scripts in the selected toolbox
    Write-Host "`nAvailable PowerShell Scripts in ${toolName}:" -ForegroundColor Cyan
    Write-Host ("=" * 69)
    Write-Host "Index".PadRight(8) + "Script Name".PadRight(45) + "Size (KB)"
    Write-Host ("-" * 8) + ("-" * 45) + ("-" * 10)

    $index = 1
    foreach ($file in $ps1Files) {
        $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        Write-Host "$index".PadRight(12) -NoNewline
        Write-Host "$scriptName".PadRight(47) -NoNewline
        Write-Host ("{0:N1}" -f ($file.Length / 1KB))
        $index++
    }

    Write-Host "`n0".PadRight(10) + "Exit" -ForegroundColor Yellow
    Write-Host "`nEnter the number corresponding to the script to run (or 0 to exit): " -NoNewline -ForegroundColor Cyan
    $selection = Read-Host


    if ($selection -eq '0') {
        Write-Host "Exiting..." -ForegroundColor Green
        break
    } elseif ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $ps1Files.Count) {
        $selectedFile = $ps1Files[[int]$selection - 1]
        Write-Host "Running script: $($selectedFile.Name)" -ForegroundColor Cyan
        Write-Host ("=" * 60)
        & "$($selectedFile.FullName)"
        Write-Host "`nScript finished. Press any key to return to menu..." -ForegroundColor Gray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        Write-Host "`nInvalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
} while ($true)