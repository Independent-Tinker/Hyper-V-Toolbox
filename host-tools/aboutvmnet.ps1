function Show-VMMenu {
    Clear-Host
    Write-Host "Hyper-V Virtual Machines" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
    Write-Host ("{0,-5} {1,-40} {2,-10}" -f "Index", "VM Name", "Status") -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------" -ForegroundColor Cyan

    $vms = Get-VM | Sort-Object Name

    if ($vms.Count -eq 0) {
        Write-Host "No virtual machines found on this Hyper-V host." -ForegroundColor Yellow
        return $null
    }

    $index = 1
    $vmMap = @{}

    foreach ($vm in $vms) {
        $state = if ($vm.State -eq "Running") { "Running" } else { "Off" }
        $color = if ($state -eq "Running") { "Green" } else { "Red" }
        Write-Host ("{0,-5} {1,-40} {2,-10}" -f $index, $vm.Name, $state) -ForegroundColor $color
        $vmMap[$index] = $vm
        $index++
    }

    Write-Host "`n0. Exit" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "`nEnter the number of the VM to see network details (0 to exit):" -ForegroundColor Cyan

    return $vmMap
}

function Show-NetworkDetails {
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine] $VM
    )

    Clear-Host
    Write-Host "Network Details for VM: $($VM.Name)" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
    Write-Host ("{0,-12} {1,-30} {2,-20}" -f "Type", "Name", "MAC Address") -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------" -ForegroundColor Cyan

    $networkAdapters = Get-VMNetworkAdapter -VMName $VM.Name

    if ($networkAdapters.Count -eq 0) {
        Write-Host "No network adapters found for this VM." -ForegroundColor Yellow
    } else {
        foreach ($adapter in $networkAdapters) {
            $switch = $null
            $type = ""
            if ($adapter.SwitchName) {
                $switch = Get-VMSwitch -Name $adapter.SwitchName -ErrorAction SilentlyContinue
                $type = if ($switch) { $switch.SwitchType } else { "Unknown" }
            } else {
                $type = "Not Connected"
            }
            Write-Host ("{0,-12} {1,-30} {2,-20}" -f $type, $adapter.SwitchName, $adapter.MacAddress) -ForegroundColor Green
        }
    }

    Write-Host "`n1. Back to Menu" -ForegroundColor Yellow
    Write-Host "0. Exit" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "`nEnter your choice:" -ForegroundColor Cyan
}


# Main script logic
do {
    $vmMap = Show-VMMenu

    if (-not $vmMap) {
        break
    }

    $selection = Read-Host

    if ($selection -eq '0') {
        break
    }

    if ($vmMap.ContainsKey([int]$selection)) {
        $selectedVM = $vmMap[[int]$selection]

        do {
            Show-NetworkDetails -VM $selectedVM
            $subSelection = Read-Host

            if ($subSelection -eq '0') {
                exit
            } elseif ($subSelection -eq '1') {
                break
            } else {
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        } while ($true)
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
} while ($true)

Write-Host "Exiting script. Goodbye!" -ForegroundColor Cyan