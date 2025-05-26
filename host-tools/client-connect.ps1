# Show current host name, list all VMs with status, and connect using VMConnect

# Get current host name
$hostName = $env:COMPUTERNAME
Write-Host "Current Host: $hostName" -ForegroundColor Cyan
Write-Host ("=" * 60)

# Get all VMs
$vms = Get-VM | Select-Object -Property Name, State

if ($vms.Count -eq 0) {
    Write-Host "No virtual machines found." -ForegroundColor Yellow
    exit
}

Write-Host "Index".PadRight(8) + "VM Name".PadRight(45) + "Status"
Write-Host ("-" * 8) + ("-" * 45) + ("-" * 10)

$index = 1
foreach ($vm in $vms) {
    Write-Host "$index".PadRight(12) -NoNewline
    Write-Host "$($vm.Name)".PadRight(47) -NoNewline
    if ($vm.State -eq "Running") {
        Write-Host "Running" -ForegroundColor Green
    } else {
        Write-Host "Down" -ForegroundColor DarkYellow
    }
    $index++
}

Write-Host "`n0".PadRight(10) + "Exit" -ForegroundColor Yellow

do {
    Write-Host "`nEnter the number of the VM to connect (or 0 to exit): " -NoNewline -ForegroundColor Cyan
    $selection = Read-Host

    if ($selection -eq '0') {
        Write-Host "Exiting..." -ForegroundColor Green
        break
    } elseif ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $vms.Count) {
        $selectedVM = $vms[[int]$selection - 1]
        $vmState = $selectedVM.State
        if ($vmState -ne "Running") {
            Write-Host "VM '$($selectedVM.Name)' is not running. Starting VM..." -ForegroundColor Yellow
            Start-VM -Name $selectedVM.Name | Out-Null
            # Wait for the VM to start
            do {
                Start-Sleep -Seconds 1
                $vmState = (Get-VM -Name $selectedVM.Name).State
            } while ($vmState -ne "Running")
            Write-Host "VM '$($selectedVM.Name)' is now running." -ForegroundColor Green
        }
        Write-Host "Launching VMConnect for '$($selectedVM.Name)'" -ForegroundColor Cyan
        Start-Process "vmconnect.exe" -ArgumentList "$hostName", "$($selectedVM.Name)"
        break
    } else {
        Write-Host "`nInvalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
} while ($true)