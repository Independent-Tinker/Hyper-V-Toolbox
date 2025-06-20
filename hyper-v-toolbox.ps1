
Write-Host @"
┏┓━┏┓━━━━━━━━━━━━━━━━━━━━━┏┓━━┏┓━━━━━┏━━━━┓━━━━━━━━┏┓━┏┓━━━━━━━━━━
┃┃━┃┃━━━━━━━━━━━━━━━━━━━━━┃┗┓┏┛┃━━━━━┃┏┓┏┓┃━━━━━━━━┃┃━┃┃━━━━━━━━━━
┃┗━┛┃┏┓━┏┓┏━━┓┏━━┓┏━┓━━━━━┗┓┃┃┏┛━━━━━┗┛┃┃┗┛┏━━┓┏━━┓┃┃━┃┗━┓┏━━┓┏┓┏┓
┃┏━┓┃┃┃━┃┃┃┏┓┃┃┏┓┃┃┏┛┏━━━┓━┃┗┛┃━┏━━━┓━━┃┃━━┃┏┓┃┃┏┓┃┃┃━┃┏┓┃┃┏┓┃┗╋╋┛
┃┃━┃┃┃┗━┛┃┃┗┛┃┃┃━┫┃┃━┗━━━┛━┗┓┏┛━┗━━━┛━┏┛┗┓━┃┗┛┃┃┗┛┃┃┗┓┃┗┛┃┃┗┛┃┏╋╋┓
┗┛━┗┛┗━┓┏┛┃┏━┛┗━━┛┗┛━━━━━━━━┗┛━━━━━━━━┗━━┛━┗━━┛┗━━┛┗━┛┗━━┛┗━━┛┗┛┗┛
━━━━━┏━┛┃━┃┃━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
━━━━━┗━━┛━┗┛━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━HOST━━━━━━━━━━
"@ -ForegroundColor Cyan

# Check for host-tools directory only
$hostToolsPath = Join-Path -Path (Get-Location) -ChildPath "host-tools"
$hostPs1Files = @()

if (Test-Path -Path $hostToolsPath -PathType Container) {
    $hostPs1Files = Get-ChildItem -Path $hostToolsPath -Filter *.ps1 | Sort-Object Name
}

if ($hostPs1Files.Count -eq 0) {
    Write-Host "No .ps1 files found in host-tools directory." -ForegroundColor Yellow
    exit
}

do {
    $ps1Files = $hostPs1Files
    $toolName = "host-tools"

    # List scripts in the host-tools toolbox
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
