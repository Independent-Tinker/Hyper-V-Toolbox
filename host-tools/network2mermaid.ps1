# List all Hyper-V switches and VM connections as a Mermaid diagram

$vmSwitches = Get-VMSwitch
$vms = Get-VM

$diagram = @()
$diagram += "flowchart TD"

# Add switches as nodes
foreach ($sw in $vmSwitches) {
    $diagram += "    $($sw.Name.Replace(' ','_'))([Switch: $($sw.Name)])"
}

# Add VMs and connections
foreach ($vm in $vms) {
    $vmNode = $vm.Name.Replace(' ','_')
    $diagram += "    $vmNode{{VM: $($vm.Name)}}"
    $adapters = Get-VMNetworkAdapter -VMName $vm.Name
    foreach ($adapter in $adapters) {
        if ($adapter.SwitchName) {
            $swNode = $adapter.SwitchName.Replace(' ','_')
            $diagram += "    $vmNode -- $($adapter.Name) --> $swNode"
        }
    }
}

# Output the diagram
$diagram -join "`n" | Set-Clipboard
Write-Host "Mermaid diagram copied to clipboard. Paste into Markdown or Mermaid Live Editor."