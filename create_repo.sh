#!/bin/bash

# Vars
REPO_NAME="Linux-25-Tasks"
COLLABORATORS=(
  "thisisamna"
  "hadeer-r"
  "HabibaYossre"
)
ATTEMPTS=0
MAX_ATTEMPTS=3
# different permissions can be set in the COLLABORATORS array
# ex: "thisisamna:admin"
# if gh repo-collab add "$REPO_NAME" "$COLLABORATOR" --permission "$PERMISSION" &>/dev/null; then

: ' 
    while ! gh auth status &>/dev/null; do
    echo "GitHub CLI is not authenticated. '"'gh auth logi'"' is ran to authenticate."
    gh auth login
    if ! gh auth status &>/dev/null; then
        echo "Authentication Failed. Try again or press ctrl+c to exit"
    fi
    done '
#it maybe a harsh approach and can be replaced with
: '
    if ! gh auth status &>/dev/null; then
      echo "GitHub CLI is not authenticated. Please run '"'gh auth login'"' to authenticate."
      exit 1
    fi
'
# best approach I've reached
echo "Checking GitHub CLI authentication..."
while ! gh auth status &>/dev/null; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
    echo "Authentication failed after $ATTEMPTS attempts. Exiting."
    exit 1
  fi
  echo "GitHub CLI is not authenticated.'gh auth login' is ran to authenticate."
  gh auth login
  if ! gh auth status &>/dev/null; then
    echo "Authentication Failed. Try again or press ctrl+c to exit"
  fi
done
echo "Github CLI is authenticated"

# Check if the repository exists if not create it
echo "Checking if repository '$REPO_NAME' exists..."
if ! gh repo view "$REPO_NAME" &>/dev/null; then
  echo "Repository '$REPO_NAME' does not exist. Creating it..."
  gh repo create "$REPO_NAME" --private --clone
  # clone if the user will use git bash not the GUI
  echo "Repository '$REPO_NAME' created successfully."
else
  echo "Repository '$REPO_NAME' already exists. Skipping creation."
fi

# Get repo prefix
USERNAME=$(gh api user --jq '.login')

# Add collaborators
for COLLABORATOR in "${COLLABORATORS[@]}"; do
  echo "Adding '$COLLABORATOR' as a collaborator..."
  if gh repo-collab add "$USERNAME"/"$REPO_NAME" "$COLLABORATOR" --permission admin &>/dev/null; then
    echo "Collaborator '$COLLABORATOR' added successfully."
  else
    echo "Failed to add '$COLLABORATOR'. They may already be a collaborator or the request failed."
  fi
done
