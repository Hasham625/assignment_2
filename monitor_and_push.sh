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

# Function to send email notification
send_email() {
  curl --request POST \
    --url https://api.sendgrid.com/v3/mail/send \
    --header "Authorization: Bearer $SENDGRID_API_KEY" \
    --header "Content-Type: application/json" \
    --data '{
      "personalizations": [{
        "to": [{"email": "'$COLLABORATORS'"}],
        "subject": "Repository Update Notification"
      }],
      "from": {"email": "'$SENDER_EMAIL'"},
      "content": [{"type": "text/plain", "value": "Changes detected in repository and pushed to GitHub."}]
    }'
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
