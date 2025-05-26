# Function to display the menu and set EnhancedSessionTransportType
function Set-EnhancedSessionTransportType {
    do {
        # Get all VMs and display them with a menu
        $vms = Get-VM | Select-Object -Property Name, EnhancedSessionTransportType
        Write-Host "Select a VM to modify its EnhancedSessionTransportType:" -ForegroundColor Cyan
        $index = 1
        foreach ($vm in $vms) {
            Write-Host "$index. $($vm.Name) (Current: $($vm.EnhancedSessionTransportType))"
            $index++
        }
        Write-Host "0. Exit" -ForegroundColor Yellow

        # Get user input
        $selection = Read-Host "Enter the number corresponding to the VM (or 0 to exit)"

        # Validate input
        if ($selection -eq '0') {
            Write-Host "Exiting..." -ForegroundColor Green
            break
        } elseif ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $vms.Count) {
            $selectedVM = $vms[[int]$selection - 1]

            # Ask the user to set EnhancedSessionTransportType
            Write-Host "Selected VM: $($selectedVM.Name)" -ForegroundColor Cyan
            Write-Host "1. Set to HVSocket"
            Write-Host "2. Set to VMBus"
            Write-Host "3. Set to Default"
            $typeSelection = Read-Host "Enter the number corresponding to the desired EnhancedSessionTransportType"

            # Apply the selected EnhancedSessionTransportType
            switch ($typeSelection) {
                '1' {
                    Set-VM -VMName $selectedVM.Name -EnhancedSessionTransportType HVSocket
                    Write-Host "EnhancedSessionTransportType set to HVSocket for VM '$($selectedVM.Name)'" -ForegroundColor Green
                }
                '2' {
                    Set-VM -VMName $selectedVM.Name -EnhancedSessionTransportType VMBus
                    Write-Host "EnhancedSessionTransportType set to VMBus for VM '$($selectedVM.Name)'" -ForegroundColor Green
                }
                '3' {
                    Set-VM -VMName $selectedVM.Name -EnhancedSessionTransportType Default
                    Write-Host "EnhancedSessionTransportType set to Default for VM '$($selectedVM.Name)'" -ForegroundColor Green
                }
                default {
                    Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                }
            }
        } else {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        }
    } while ($true)
}

# Run the function
Set-EnhancedSessionTransportType

