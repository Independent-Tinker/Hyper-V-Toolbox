# Script to pass through a USB device to Hyper-V VM
# Make sure to run as Administrator

# Parameters
$usbDeviceDescription = "TP-Link Wireless MU-MIMO USB Adapter" # Exact device name

# Check for admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run as Administrator"
    Exit
}

# List all VMs
$vms = Get-VM | Sort-Object Name
if ($vms.Count -eq 0) {
    Write-Host "No virtual machines found on this Hyper-V host." -ForegroundColor Yellow
    exit
}

Write-Host "Available Hyper-V Virtual Machines:" -ForegroundColor Cyan
Write-Host ("{0,-5} {1,-40} {2,-10}" -f "Index", "VM Name", "Status") -ForegroundColor Yellow
Write-Host ("-" * 5) + " " + ("-" * 40) + " " + ("-" * 10)
$index = 1
foreach ($vm in $vms) {
    Write-Host ("{0,-5} {1,-40} {2,-10}" -f $index, $vm.Name, $vm.State) -ForegroundColor White
    $index++
}
Write-Host ("-" * 60)
Write-Host "0. Exit" -ForegroundColor Yellow

# Prompt user to select a VM
do {
    $selection = Read-Host "Enter the index number of the VM to attach the USB device"
    if ($selection -eq '0') {
        Write-Host "Exiting..." -ForegroundColor Green
        exit
    }
    $selectionInt = 0
    if ([int]::TryParse($selection, [ref]$selectionInt) -and $selectionInt -ge 1 -and $selectionInt -le $vms.Count) {
        $selectedVM = $vms[$selectionInt - 1]
        $vmName = $selectedVM.Name
        break
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
    }
} while ($true)

# Stop the VM if it's running
if ($selectedVM.State -eq "Running") {
    Write-Host "Stopping VM '$vmName' to attach device..." -ForegroundColor Yellow
    Stop-VM -Name $vmName -Force
}

# Get USB device
$usbDevice = Get-PnpDevice -FriendlyName $usbDeviceDescription -ErrorAction SilentlyContinue

if (-not $usbDevice) {
    Write-Error "USB device matching '$usbDeviceDescription' not found. Try these devices:"
    Get-PnpDevice -Class "USB" | Select-Object FriendlyName, InstanceId | Format-Table -AutoSize
    Exit
}

# Get device instance ID
$instanceId = $usbDevice.InstanceId

Write-Host "Found USB device: $($usbDevice.FriendlyName), ID: $instanceId" -ForegroundColor Green

try {
    # Dismount from host
    $hardwareId = (Get-PnpDeviceProperty -InstanceId $instanceId -KeyName DEVPKEY_Device_HardwareIds).Data[0]
    Disable-PnpDevice -InstanceId $instanceId -Confirm:$false

    # Add device to VM
    Add-VMAssignableDevice -LocationPath $instanceId -VMName $vmName

    # Start the VM
    Start-VM -Name $vmName

    Write-Host "USB device has been passed through to VM '$vmName'" -ForegroundColor Green
    Write-Host "Note: You may need to install device drivers inside the VM"
} catch {
    Write-Error "Error attaching device: $_"
    # Re-enable device on host if there was an error
    Enable-PnpDevice -InstanceId $instanceId -Confirm:$false
}