#!/bin/bash

# Define the log file and password file paths
LOGFILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

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

# Check if the log file exists, create it if it doesn't, and set the correct permissions
if [[ ! -f "$LOGFILE" ]]; then
  touch "$LOGFILE"
  log_action "Created log file: $LOGFILE"
else
  log_action "Log file already exists, skipping creation of logfile ' $LOGFILE ' "
fi
  log_action "Setting permissions for password file: $PASSWORD_FILE"
chmod 600 "$LOGFILE"
log_action "Successfully set"

# Check if the password file exists, create it if it doesn't, and set the correct permissions
if [[ ! -f "$PASSWORD_FILE" ]]; then
  touch "$PASSWORD_FILE"
  log_action "Created password file: $PASSWORD_FILE"
else
  log_action "Password file already exists, skipping creating of password file ' $PASSWORD_FILE ' "
fi
  log_action "Setting permissions for password file: $PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"
log_action "Successfully set"

# Function to generate random passwords
generate_password() {
  local password_length=12
  tr -dc A-Za-z0-9 </dev/urandom | head -c $password_length
}


create_user() {
  local username="$1"
  local groups="$2"

  log_action "Processing user: $username with groups: $groups"

  # Check if the user already exists
  if id "$username" &>/dev/null; then
    log_action "User $username already exists, skipping creation"
    return 1
  fi

  # Create the user with a home directory
  useradd -m "$username"
  if [[ $? -ne 0 ]]; then
    log_action "Failed to create user: $username"
    return 1
  fi

  # Create a personal group for the user
  groupadd "$username"
  if [[ $? -ne 0 ]]; then
    log_action "Failed to create group: $username"
    return 1
  fi

  # Add the user to the personal group
  usermod -aG "$username" "$username"

  # Add the user to additional groups
  IFS=',' read -ra ADDR <<< "$groups"
  for group in "${ADDR[@]}"; do
    groupadd "$group" 2>/dev/null
    usermod -aG "$group" "$username"
  done

  # Set up home directory permissions
  chown -R "$username":"$username" "/home/$username"
  chmod 700 "/home/$username"

  # Generate a password and set it for the user
  password=$(generate_password)
  echo "$username:$password" | chpasswd

  # Log the user creation and password
  log_action "Created user: $username with groups: $groups"
  echo "$username,$password" >> "$PASSWORD_FILE"
}

# Define a function to read the file
read_file() {
  local filename="$1"  # The filename is passed as an argument to the function

  # Check if the file exists
  if [[ ! -f "$filename" ]]; then
    log_action "File not found: $filename"
    return 1
  fi

  # Read the file line by line
  while IFS= read -r line; do
    # Remove whitespace and extract user and groups
    local user=$(echo "$line" | cut -d ';' -f 1 | xargs)  # Declares 'user' as local
    local groups=$(echo "$line" | cut -d ';' -f 2 | xargs)  # Declares 'groups' as local

    # Create the user and groups
    create_user "$user" "$groups"
  done < "$filename"
}

# Call the function with the filename passed as a script argument
read_file "$1"
