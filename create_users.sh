#!/bin/bash

# Define the log file and password file paths
LOGFILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"
SECURE_DIR="/var/secure/"

# Ensure the script is run with root permissions
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root or with sudo"
  exit 1
fi

# Function to log actions
log_action() {
  local message="$1"
  echo "$message" | tee -a "$LOGFILE"
}


# Function to check if a group already exists
does_group_exists() {
    local group_name=$1
    if getent group "$group_name" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to generate random passwords
generate_password() {
  local password_length=12
  tr -dc A-Za-z0-9 </dev/urandom | head -c $password_length
}

# Check if the log file exists, create it if it doesn't, and set the correct permissions
if [[ ! -f "$LOGFILE" ]]; then
  touch "$LOGFILE"
  log_action "Created log file: $LOGFILE"
else
  log_action "Log file already exists, skipping creation of logfile ' $LOGFILE ' "
fi

# Check if the password file exists, create it if it doesn't, and set the correct permissions
if [[ ! -f "$PASSWORD_FILE" ]]; then
  mkdir -p SECURE_DIR
  touch "$PASSWORD_FILE"
  log_action "Created password file: $PASSWORD_FILE"
  chmod 600 "$PASSWORD_FILE"
  log_action "Password file permissions set to 600: $PASSWORD_FILE"
else
  log_action "Password file already exists, skipping creation of password file: $PASSWORD_FILE"
fi

# Define a function to read the file
create_user_groups_from_file() {
  local filename="$1"  # The filename is passed as an argument to the function

  # Check if the file exists
  if [[ ! -f "$filename" ]]; then
    log_action "File not found: $filename"
    return 1
  fi

  # Read the file line by line
  while IFS=';' read -r username groups; do
    # Remove whitespace and extract user and groups
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | tr -d ' ')

  # Check if the user already exists
  if ! id "$username" &>/dev/null; then
    # Create the user with a home directory
    useradd -m -s /bin/bash "$username"
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to create user $username." >> "$LOG_FILE"
        continue
    fi
        log_action "User $username created."

    # Generate a password and set it for the user
    password=$(generate_password)
    # and set password
    echo "$username:$password" | chpasswd
    echo "$username,$password" >> "$PASSWORD_FILE"
    log_action "Created user: $username"
  else
    log_action "User $username already exists, skipping creation"
  fi

  # Create a personal group for the user if it doesn't exist
  if ! does_group_exists "$username"; then
        groupadd "$username"
        log_action "Successfully created group: $username"
        usermod -aG "$username" "$username"
        log_action "User: $username added to Group: $username"
    else
        log_action "User: $username added to Group: $username"
    fi

 
  # Add the user to additional groups
  IFS=',' read -r -a group_lst <<< "$groups"
  for group in "${group_lst[@]}"; do
    if ! does_group_exists "$group"; then
            # Create the group if it does not exist
            groupadd "$group"
            log_action "Successfully created Group: $group"
        else
            log_action "Group: $group already exists"
        fi
        # Add the user to the group
        usermod -aG "$group" "$username"
   done

  # Set up home directory permissions
  chown -R "$username:$username" "/home/$username"
  chmod 700 "/home/$username"

  done < "$filename"
}

# Call the function with the filename passed as a script argument
create_user_groups_from_file "$1"
