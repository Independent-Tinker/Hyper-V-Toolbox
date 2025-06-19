# Display processor type and check if VT-x and EPT are enabled

# Get processor information
$cpu = Get-CimInstance -ClassName Win32_Processor

Write-Host "Processor Name: $($cpu.Name)" -ForegroundColor Cyan
Write-Host "Manufacturer:  $($cpu.Manufacturer)"
Write-Host "Description:   $($cpu.Description)"
Write-Host ("=" * 60)

# Check for VT-x (Intel Virtualization Technology)
$vtSupport = $false
$eptSupport = $false

# VT-x and EPT are Intel features; for AMD, look for AMD-V and RVI/NPT
if ($cpu.Manufacturer -like "*Intel*") {
    $vtSupport = ($cpu.VirtualizationFirmwareEnabled -eq $true) -or ($cpu.SecondLevelAddressTranslationExtensions -eq $true)
    $eptSupport = ($cpu.SecondLevelAddressTranslationExtensions -eq $true)
    Write-Host "VT-x (Intel Virtualization): " -NoNewline
    if ($vtSupport) {
        Write-Host "Enabled" -ForegroundColor Green
    } else {
        Write-Host "Disabled" -ForegroundColor Red
    }
    Write-Host "EPT (Extended Page Tables): " -NoNewline
    if ($eptSupport) {
        Write-Host "Enabled" -ForegroundColor Green
    } else {
        Write-Host "Disabled" -ForegroundColor Red
    }
} elseif ($cpu.Manufacturer -like "*AMD*") {
    $amdV = ($cpu.VirtualizationFirmwareEnabled -eq $true)
    $rvi = ($cpu.SecondLevelAddressTranslationExtensions -eq $true)
    Write-Host "AMD-V (AMD Virtualization): " -NoNewline
    if ($amdV) {
        Write-Host "Enabled" -ForegroundColor Green
    } else {
        Write-Host "Disabled" -ForegroundColor Red
    }
    Write-Host "RVI/NPT (Rapid Virtualization Indexing/Nested Page Tables): " -NoNewline
    if ($rvi) {
        Write-Host "Enabled" -ForegroundColor Green
    } else {
        Write-Host "Disabled" -ForegroundColor Red
    }
} else {
    Write-Host "Unknown CPU manufacturer or unable to determine virtualization features." -ForegroundColor Yellow
}