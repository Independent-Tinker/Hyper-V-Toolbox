# List all VMs with their VMProcessor ExposeVirtualizationExtensions property and allow toggling

function Show-VMs {
    Clear-Host
    $global:vms = Get-VM | Select-Object -Property Name
    if ($vms.Count -eq 0) {
        Write-Host "No virtual machines found." -ForegroundColor Yellow
        exit
    }
    Write-Host "`nVMs and their ExposeVirtualizationExtensions setting:" -ForegroundColor Cyan
    Write-Host ("=" * 60)
    Write-Host "Index".PadRight(8) + "Name".PadRight(45) + "ExposeVirtExt"
    Write-Host ("-" * 8) + ("-" * 45) + ("-" * 15)

    $global:exposeList = @()
    $index = 1
    foreach ($vm in $vms) {
        $expose = (Get-VMProcessor -VMName $vm.Name).ExposeVirtualizationExtensions
        $global:exposeList += $expose
        Write-Host "$index".PadRight(12) -NoNewline
        Write-Host "$($vm.Name)".PadRight(47) -NoNewline
        if ($expose) {
            Write-Host "True" -ForegroundColor Green
        } else {
            Write-Host "False" -ForegroundColor Red
        }
        $index++
    }
    Write-Host "`n0".PadRight(10) + "Exit" -ForegroundColor Yellow
}

do {
    Show-VMs
    Write-Host "`nEnter the number of the VM to toggle ExposeVirtualizationExtensions (or 0 to exit): " -NoNewline -ForegroundColor Cyan
    $selection = Read-Host

    if ($selection -eq '0') {
        Write-Host "Exiting..." -ForegroundColor Green
        break
    } elseif ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $vms.Count) {
        $selectedVM = $vms[[int]$selection - 1]
        $current = $exposeList[[int]$selection - 1]
        Clear-Host
        Write-Host "Selected VM: $($selectedVM.Name)" -ForegroundColor Cyan
        Write-Host "Current ExposeVirtualizationExtensions: " -NoNewline
        if ($current) {
            Write-Host "True" -ForegroundColor Green
        } else {
            Write-Host "False" -ForegroundColor Red
        }
        Write-Host "`n1. Set to True"
        Write-Host "2. Set to False"
        Write-Host "0. Cancel" -ForegroundColor Yellow
        Write-Host "`nEnter your choice: " -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        switch ($choice) {
            '1' {
                Set-VMProcessor -VMName $selectedVM.Name -ExposeVirtualizationExtensions $true
                Write-Host "`nExposeVirtualizationExtensions set to True for VM '$($selectedVM.Name)'" -ForegroundColor Green
            }
            '2' {
                Set-VMProcessor -VMName $selectedVM.Name -ExposeVirtualizationExtensions $false
                Write-Host "`nExposeVirtualizationExtensions set to False for VM '$($selectedVM.Name)'" -ForegroundColor Green
            }
            '0' {
                Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            }
            default {
                Write-Host "`nInvalid selection. Please try again." -ForegroundColor Red
            }
        }
        Write-Host "`nPress any key to return to the list..." -ForegroundColor Gray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        Write-Host "`nInvalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
} while ($true)