# Enable required features
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# (Optional, for Hyper-V support)
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart

# Restart to apply changes
Restart-Computer