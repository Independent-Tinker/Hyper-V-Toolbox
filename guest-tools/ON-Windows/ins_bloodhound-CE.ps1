curl.exe -L -o "$env:USERPROFILE\Downloads\bloodhound-cli-windows-amd64.zip" https://github.com/SpecterOps/bloodhound-cli/releases/latest/download/bloodhound-cli-windows-amd64.zip
cd "$env:USERPROFILE\Downloads"; tar -xf bloodhound-cli-windows-amd64.zip
.\bloodhound-cli install
