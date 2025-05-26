Clear-Host
Write-Host "All Hyper-V Virtual Switches" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------" -ForegroundColor Cyan

# List all switches first
$switches = Get-VMSwitch | Sort-Object Name
if ($switches.Count -eq 0) {
    Write-Host "No virtual switches found on this Hyper-V host." -ForegroundColor Yellow
    exit
}

foreach ($sw in $switches) {
    Write-Host ("Name: {0,-25} Type: {1,-10} Notes: {2}" -f $sw.Name, $sw.SwitchType, $sw.Notes) -ForegroundColor Yellow
}
Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""

# For each switch, list all VMs attached
foreach ($sw in $switches) {
    Write-Host ("Switch: {0} ({1})" -f $sw.Name, $sw.SwitchType) -ForegroundColor Green
    Write-Host ("{0,-5} {1,-40} {2,-20}" -f "Index", "VM Name", "Adapter MAC") -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------" -ForegroundColor Cyan

    $index = 1
    $found = $false
    $vms = Get-VM | Sort-Object Name
    foreach ($vm in $vms) {
        $adapters = Get-VMNetworkAdapter -VMName $vm.Name | Where-Object { $_.SwitchName -eq $sw.Name }
        foreach ($adapter in $adapters) {
            Write-Host ("{0,-5} {1,-40} {2,-20}" -f $index, $vm.Name, $adapter.MacAddress) -ForegroundColor White
            $index++
            $found = $true
        }
    }
    if (-not $found) {
        Write-Host "No VMs connected to this switch." -ForegroundColor DarkGray
    }
    Write-Host ""
}

Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
Write-Host "End of list." -ForegroundColor Cyan