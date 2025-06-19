
# Function to display the menu and set EnhancedSessionTransportType
function Set-EnhancedSessionTransportType {
    do {
        Clear-Host
        # Get all VMs and display them with a formatted menu
        $vms = Get-VM | Select-Object -Property Name, EnhancedSessionTransportType
        if ($vms.Count -eq 0) {
            Write-Host "No virtual machines found." -ForegroundColor Yellow
            break
        }

        Write-Host "`nSelect a VM to modify its EnhancedSessionTransportType:" -ForegroundColor Cyan
        Write-Host ("=" * 60)
        Write-Host "Index".PadRight(8) + "Name".PadRight(45) + "Transport Type"
        Write-Host ("-" * 8) + ("-" * 45) + ("-" * 20)

        $index = 1
        foreach ($vm in $vms) {
            Write-Host "$index".PadRight(12) -NoNewline
            Write-Host "$($vm.Name)".PadRight(47) -NoNewline
            Write-Host "$($vm.EnhancedSessionTransportType)"
            $index++
        }

        Write-Host "`n0".PadRight(10) + "Exit" -ForegroundColor Yellow

        # Get user input
        Write-Host "`nEnter the number corresponding to the VM (or 0 to exit): " -NoNewline -ForegroundColor Cyan
        $selection = Read-Host

        # Validate input
        if ($selection -eq '0') {
            Write-Host "Exiting..." -ForegroundColor Green
            break
        } elseif ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $vms.Count) {
            $selectedVM = $vms[[int]$selection - 1]

            # Ask the user to set EnhancedSessionTransportType
            Clear-Host
            Write-Host "`nSelected VM: $($selectedVM.Name)" -ForegroundColor Cyan
            Write-Host "Current EnhancedSessionTransportType: $($selectedVM.EnhancedSessionTransportType)" -ForegroundColor Yellow
            Write-Host "`n1. Set to HVSocket"
            Write-Host "2. Set to VMBus"
            Write-Host "3. Set to Default"
            Write-Host "0. Cancel" -ForegroundColor Yellow

            Write-Host "`nEnter the number corresponding to the desired EnhancedSessionTransportType: " -NoNewline -ForegroundColor Cyan
            $typeSelection = Read-Host

            # Apply the selected EnhancedSessionTransportType
            switch ($typeSelection) {
                '1' {
                    Set-VM -VMName $selectedVM.Name -EnhancedSessionTransportType HVSocket
                    Write-Host "`nEnhancedSessionTransportType set to HVSocket for VM '$($selectedVM.Name)'" -ForegroundColor Green
                }
                '2' {
                    Set-VM -VMName $selectedVM.Name -EnhancedSessionTransportType VMBus
                    Write-Host "`nEnhancedSessionTransportType set to VMBus for VM '$($selectedVM.Name)'" -ForegroundColor Green
                }
                '3' {
                    Set-VM -VMName $selectedVM.Name -EnhancedSessionTransportType Default
                    Write-Host "`nEnhancedSessionTransportType set to Default for VM '$($selectedVM.Name)'" -ForegroundColor Green
                }
                '0' {
                    Write-Host "`nOperation cancelled." -ForegroundColor Yellow
                }
                default {
                    Write-Host "`nInvalid selection. Please try again." -ForegroundColor Red
                }
            }

            Write-Host "`nPress any key to continue..." -ForegroundColor Gray
            $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        } else {
            Write-Host "`nInvalid selection. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    } while ($true)
}

# Run the function
Set-EnhancedSessionTransportType