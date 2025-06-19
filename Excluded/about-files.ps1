function List-VMFiles {
    param (
        [string]$Path,
        [string]$Desc,
        [string]$VMName,
        [string]$VMId
    )
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path)) {
        Write-Host "$Desc path not found: $Path" -ForegroundColor DarkYellow
        return
    }
    Write-Host "`nFiles in $Desc path ($Path) for VM:" -ForegroundColor Green
    $files = Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue | Where-Object {
        $_.FullName -match [regex]::Escape($VMId) -or $_.FullName -match [regex]::Escape($VMName)
    }
    if ($files) {
        foreach ($file in $files) {
            Write-Host " - $($file.FullName)" -ForegroundColor White
        }
    } else {
        Write-Host "No files found for this VM in $Desc path." -ForegroundColor DarkYellow
    }
}

Clear-Host
Write-Host "All Hyper-V Virtual Machines and their GUIDs" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------" -ForegroundColor Cyan

$vms = Get-VM | Sort-Object Name

if ($vms.Count -eq 0) {
    Write-Host "No virtual machines found on this Hyper-V host." -ForegroundColor Yellow
    exit
}

Write-Host ("{0,-5} {1,-40} {2,-38}" -f "Index", "VM Name", "VM GUID") -ForegroundColor Yellow
Write-Host "----------------------------------------------------------" -ForegroundColor Cyan

$index = 1
foreach ($vm in $vms) {
    Write-Host ("{0,-5} {1,-40} {2,-38}" -f $index, $vm.Name, $vm.Id) -ForegroundColor White
    $index++
}

Write-Host "----------------------------------------------------------" -ForegroundColor Cyan

# Prompt user to select a VM
$selection = Read-Host "Enter the index number of the VM to inspect"
if (-not ($selection -as [int]) -or $selection -lt 1 -or $selection -gt $vms.Count) {
    Write-Host "Invalid selection. Exiting." -ForegroundColor Red
    exit
}

$selectedVM = $vms[$selection - 1]
Write-Host "`nSelected VM: $($selectedVM.Name) (GUID: $($selectedVM.Id))" -ForegroundColor Cyan

# Get VM configuration
try {
    $vmDrives = Get-VMHardDiskDrive -VM $selectedVM -ErrorAction Stop
    $vmCheckpoints = Get-VMSnapshot -VM $selectedVM -ErrorAction SilentlyContinue
    $vmConfigPath = $selectedVM.ConfigurationLocation
    $vmSnapshotPath = $selectedVM.SnapshotFileLocation
    $vmSmartPagingPath = $selectedVM.SmartPagingFilePath
} catch {
    Write-Host "Error retrieving VM details: $_" -ForegroundColor Red
    exit
}

Write-Host "`nVM Configuration Path: $vmConfigPath" -ForegroundColor Yellow
Write-Host "VM Snapshot Path: $vmSnapshotPath" -ForegroundColor Yellow
Write-Host "VM Smart Paging Path: $vmSmartPagingPath" -ForegroundColor Yellow

# List all hard drive files
Write-Host "`nHard Drive Files:" -ForegroundColor Green
if ($vmDrives) {
    foreach ($drive in $vmDrives) {
        Write-Host " - $($drive.Path)" -ForegroundColor White
    }
} else {
    Write-Host "No hard drives found." -ForegroundColor DarkYellow
}

# List all checkpoint/snapshot files
Write-Host "`nCheckpoint/Snapshot Files:" -ForegroundColor Green
if ($vmCheckpoints) {
    foreach ($cp in $vmCheckpoints) {
        if ($cp.Path -and ($cp.Path -match [regex]::Escape($selectedVM.Id) -or $cp.Path -match [regex]::Escape($selectedVM.Name))) {
            Write-Host " - $($cp.Path)" -ForegroundColor White
        }
    }
} else {
    Write-Host "No checkpoints/snapshots found." -ForegroundColor DarkYellow
}

# List only files related to this VM in config, snapshot, and smart paging directories
List-VMFiles -Path $vmConfigPath -Desc "Configuration" -VMName $selectedVM.Name -VMId $selectedVM.Id
List-VMFiles -Path $vmSnapshotPath -Desc "Snapshot" -VMName $selectedVM.Name -VMId $selectedVM.Id
List-VMFiles -Path $vmSmartPagingPath -Desc "Smart Paging" -VMName $selectedVM.Name -VMId $selectedVM.Id

Write-Host "`nAll files associated with VM '$($selectedVM.Name)' (GUID: $($selectedVM.Id)) have been listed." -ForegroundColor Cyan