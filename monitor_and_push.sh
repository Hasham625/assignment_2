#!/bin/bash

# Load Configuration
source config.cfg

# Variables
LAST_HASH=""

# Check if repository exists
if [[ ! -d "$REPO_PATH/.git" ]]; then
  echo "Error: Not a Git repository!"
  exit 1
fi

# Function to send email notification using PowerShell
send_email() {
  powershell.exe -Command "& {
    Send-MailMessage -SmtpServer '$SMTP_SERVER' -Port '$SMTP_PORT' -UseSsl `
      -Credential (New-Object System.Management.Automation.PSCredential('$GMAIL_USER', (ConvertTo-SecureString '$GMAIL_PASSWORD' -AsPlainText -Force))) `
      -From '$GMAIL_USER' -To '$COLLABORATORS' -Subject '$EMAIL_SUBJECT' -Body '$EMAIL_BODY'
  }"
}

# Monitor file for changes
while true; do
  NEW_HASH=$(sha256sum "$MONITOR_PATH" | awk '{print $1}')
  
  if [[ "$NEW_HASH" != "$LAST_HASH" ]]; then
    echo "Change detected in $MONITOR_PATH..."
    
    # Stage, commit, and push changes
    cd "$REPO_PATH"
    git add .
    git commit -m "Auto-commit: Changes detected in $MONITOR_PATH"
    
    if git push "$GIT_REMOTE" "$GIT_BRANCH"; then
      echo "Changes pushed successfully."
      send_email
    else
      echo "Error: Git push failed!"
    fi
    
    # Update hash
    LAST_HASH="$NEW_HASH"
  fi
  
  # Wait for 5 seconds before checking again
  sleep 5
done
