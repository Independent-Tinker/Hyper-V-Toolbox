#!/bin/bash
cat <<'EOF'
┏┓━┏┓━━━━━━━━━━━━━━━━━━━━━┏┓━━┏┓━━━━━┏━━━━┓━━━━━━━━┏┓━┏┓━━━━━━━━━━
┃┃━┃┃━━━━━━━━━━━━━━━━━━━━━┃┗┓┏┛┃━━━━━┃┏┓┏┓┃━━━━━━━━┃┃━┃┃━━━━━━━━━━
┃┗━┛┃┏┓━┏┓┏━━┓┏━━┓┏━┓━━━━━┗┓┃┃┏┛━━━━━┗┛┃┃┗┛┏━━┓┏━━┓┃┃━┃┗━┓┏━━┓┏┓┏┓
┃┏━┓┃┃┃━┃┃┃┏┓┃┃┏┓┃┃┏┛┏━━━┓━┃┗┛┃━┏━━━┓━━┃┃━━┃┏┓┃┃┏┓┃┃┃━┃┏┓┃┃┏┓┃┗╋╋┛
┃┃━┃┃┃┗━┛┃┃┗┛┃┃┃━┫┃┃━┗━━━┛━┗┓┏┛━┗━━━┛━┏┛┗┓━┃┗┛┃┃┗┛┃┃┗┓┃┗┛┃┃┗┛┃┏╋╋┓
┗┛━┗┛┗━┓┏┛┃┏━┛┗━━┛┗┛━━━━━━━━┗┛━━━━━━━━┗━━┛━┗━━┛┗━━┛┗━┛┗━━┛┗━━┛┗┛┗┛
━━━━━┏━┛┃━┃┃━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
━━━━━┗━━┛━┗┛━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━GUEST━━━━━━━━━━
EOF

# Set guest-tools directory
guest_tools_dir="$(dirname "$0")/guest-tools"
if [[ ! -d "$guest_tools_dir" ]]; then
    guest_tools_dir="$(dirname "$0")/Guest-tools"
fi

if [[ ! -d "$guest_tools_dir" ]]; then
    echo "No guest-tools directory found." >&2
    exit 1
fi

# Find all .sh scripts in guest-tools
mapfile -t sh_files < <(find "$guest_tools_dir" -maxdepth 1 -type f -name "*.sh" | sort)

if [[ ${#sh_files[@]} -eq 0 ]]; then
    echo "No .sh files found in guest-tools directory."
    exit 1
fi

while true; do
    echo
    echo "Available Bash Scripts in guest-tools:"
    printf "%-8s%-45s%s\n" "Index" "Script Name" "Size (KB)"
    printf "%-8s%-45s%s\n" "------" "---------------------------------------------" "---------"
    idx=1
    for script in "${sh_files[@]}"; do
        script_name=$(basename "$script" .sh)
        size_kb=$(awk "BEGIN {printf \"%.1f\", $(stat -c%s "$script")/1024}")
        printf "%-8s%-45s%s\n" "$idx" "$script_name" "$size_kb"
        ((idx++))
    done
    echo -e "\n0       Exit"
    echo -n -e "\nEnter the number corresponding to the script to run (or 0 to exit): "
    read -r selection

    if [[ "$selection" == "0" ]]; then
        echo "Exiting..."
        break
    elif [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#sh_files[@]} )); then
        selected_script="${sh_files[selection-1]}"
        echo "Running script: $(basename "$selected_script")"
        echo "============================================================"
        bash "$selected_script"
        echo -e "\nScript finished. Press Enter to return to menu..."
        read -r
    else
        echo -e "\nInvalid selection. Please try again."
        sleep 1
    fi
done