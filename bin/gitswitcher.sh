#!/bin/bash

PROFILE_FILE="${SSH_PROFILE_FILE:-$HOME/.ssh/profiles.txt}"
SSH_DIR="${SSH_DIR:-$HOME/.ssh}"
CONFIG_FILE="${SSH_CONFIG_FILE:-$SSH_DIR/config}"
CONFIG_BACKUP_FILE="${SSH_CONFIG_BACKUP_FILE:-$SSH_DIR/config.bak}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

if [[ ! -d "$SSH_DIR" ]]; then
    mkdir -p "$SSH_DIR"
    echo -e "${GREEN}Created new SSH directory: $SSH_DIR${RESET}"
fi

if [[ ! -f "$PROFILE_FILE" ]]; then
    touch "$PROFILE_FILE"
    echo -e "${GREEN}Created new profiles file: $PROFILE_FILE${RESET}"
fi

add_ssh_key() {
    local key_path="$1"
    echo -e "${YELLOW}Adding SSH key from $key_path to the agent...${RESET}"
    ssh-add "$key_path" > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SSH key added successfully.${RESET}"
    else
        echo -e "${RED}Failed to add SSH key.${RESET}"
        exit 1
    fi
}

update_ssh_config() {
    local key_path="$1"
    local username="$2"

    echo -e "${YELLOW}Creating or updating SSH config at $CONFIG_FILE${RESET}"

    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$CONFIG_BACKUP_FILE"
    fi

    {
        echo "Host ${username}.github.com"
        echo "  HostName github.com"
        echo "  User git"
        echo "  IdentityFile $key_path"
        echo "  IdentitiesOnly yes"
    } > "$CONFIG_FILE"

    chmod 600 "$CONFIG_FILE"
}

switch_profile() {
    local key_path="$1"
    local username="$2"
    local email="$3"

    echo -e "${YELLOW}Switching to profile: $username${RESET}"
    
    if [[ ! -f "$key_path" ]]; then
        echo -e "${YELLOW}Generating SSH key for $email at $key_path${RESET}"
        ssh-keygen -t rsa -b 4096 -C "$email" -f "$key_path" -N ""
        
        if [[ -f "${key_path}.pub" ]]; then
            echo -e "${BLUE}Here is your public key:${RESET}"
            cat "${key_path}.pub"
            echo
            echo -e "${YELLOW}Please follow these instructions to add your SSH key to GitHub:${RESET}"
            echo -e "1. Go to your GitHub account settings: ${BLUE}https://github.com/settings/keys${RESET}"
            echo -e "2. Click on 'New SSH key'."
            echo -e "3. Copy the entire public key from above and paste it into the 'Key' field."
            echo -e "4. Provide a descriptive title for the key and click 'Add SSH key'."
            echo -e "5. Press Enter after adding the key to GitHub to continue."
            read -p "Press Enter after adding the key to GitHub to continue..."
        fi
    fi

    ssh-add -D
    if ! ssh-add -l | grep -q "$key_path"; then
        add_ssh_key "$key_path"
    else
        echo -e "${GREEN}SSH key for $key_path is already added to the agent.${RESET}"
    fi

    update_ssh_config "$key_path" "$username"

    git config --global user.name "$username"
    git config --global user.email "$email"

    echo -e "${GREEN}Profile switched to $username.${RESET}"

    echo -e "${BLUE}Here is the fingerprint for your SSH key:${RESET}"
    ssh-keygen -lf "$key_path"
    echo

    echo -e "${YELLOW}Testing SSH connection to GitHub...${RESET}"
    ssh -T "git@${username}.github.com"
}

add_new_profile() {
    echo -e "${YELLOW}Enter the username for the new profile:${RESET}"
    read -rp "Username: " new_username
    echo -e "${YELLOW}Enter the email for the new profile:${RESET}"
    read -rp "Email: " new_email

    new_key_path="$SSH_DIR/id_rsa_${new_username}"

    if grep -q "$new_username" "$PROFILE_FILE"; then
        echo -e "${RED}Profile for username $new_username already exists.${RESET}"
        exit 1
    fi

    echo "$new_username $new_email" >> "$PROFILE_FILE"
    switch_profile "$new_key_path" "$new_username" "$new_email"
}

remove_profile() {
    echo -e "${YELLOW}Enter the username of the profile to remove:${RESET}"
    read -rp "Username: " remove_username

    if ! grep -q "$remove_username" "$PROFILE_FILE"; then
        echo -e "${RED}Profile for username $remove_username not found.${RESET}"
        exit 1
    fi

    grep -v "$remove_username" "$PROFILE_FILE" > "${PROFILE_FILE}.tmp"
    mv "${PROFILE_FILE}.tmp" "$PROFILE_FILE"

    key_path="$SSH_DIR/id_rsa_${remove_username}"
    if [[ -f "$key_path" ]]; then
        rm "$key_path"
        rm "${key_path}.pub"
        echo -e "${GREEN}Removed SSH key files for $remove_username.${RESET}"
    fi

    if [[ -f "$CONFIG_FILE" ]]; then
        grep -v "Host $remove_username.github.com" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        echo -e "${GREEN}Removed SSH config entry for $remove_username.${RESET}"
    fi

    echo -e "${GREEN}Profile $remove_username has been removed.${RESET}"
}

while true; do
    echo -e "${BLUE}Select an option:${RESET}"
    echo -e "1. Setup a new SSH profile"
    echo -e "2. Switch between existing profiles"
    echo -e "3. Remove an existing profile"
    echo -e "4. Exit"
    read -rp "Enter your choice (1, 2, 3, or 4): " choice

    case "$choice" in
        1) add_new_profile ;;
        2)
            if [[ ! -s "$PROFILE_FILE" ]]; then
                echo -e "${RED}No profiles found. Please add a new profile first.${RESET}"
                continue
            fi

            echo -e "${BLUE}Switch between existing profiles:${RESET}"
            cat "$PROFILE_FILE" | while read -r line; do
                username=$(echo "$line" | awk '{print $1}')
                email=$(echo "$line" | awk '{print $2}')
                echo -e "${YELLOW}$username (${email})${RESET}"
            done

            read -rp "Enter the username of the profile to switch to: " switch_username

            profile=$(grep "$switch_username" "$PROFILE_FILE")
            if [[ -z "$profile" ]]; then
                echo -e "${RED}Profile not found.${RESET}"
                continue
            fi

            switch_username=$(echo "$profile" | awk '{print $1}')
            switch_email=$(echo "$profile" | awk '{print $2}')
            switch_key_path="$SSH_DIR/id_rsa_${switch_username}"

            switch_profile "$switch_key_path" "$switch_username" "$switch_email"
            ;;
        3) remove_profile ;;
        4) echo -e "${GREEN}Exiting.${RESET}"; exit ;;
        *) echo -e "${RED}Invalid choice.${RESET}" ;;
    esac
done
