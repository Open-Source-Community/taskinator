#!/bin/bash

# only run once
# by members
# prerequistes: gh, git

username=$(gh api user --jq '.login')
collaborators=('thisisamna' 'hadeer-r' 'HabibaYossre' 'Momen-MKadry')
repo_name="Linux-25-Training"

add_collaborators() {
  for c in "${collaborators[@]}"
  do
    gh api -X PUT "/repos/$username/$repo_name/collaborators/$c" -f permission=write &> /dev/null
  done
}

# Check if dir with the same name already exists
if [ -d $repo_name ]; then
  echo "A directory with the name $repo_name already exists! Exiting..."
  exit 1
fi

# Check if remote repo already exists 
gh api repos/"$username/$repo_name" &> /dev/null
if [ $? = 0 ]; then
  echo "Repo already exists on GitHub. Cloning..."
  # Re-adding collaborators just in case
  add_collaborators 
  gh repo clone "$username/$repo_name" &> /dev/null || exit 1
  echo "Existing task repo cloned successfully!"
  exit 0
fi

# Creating a new repo
echo "Creating new task repo..."
{
  git init -b main $repo_name 
  cd $repo_name
  git commit --allow-empty -m "repository setup"
  gh repo create $repo_name --private --source=. --remote=origin
  git push -u origin main
  add_collaborators
} &> /dev/null 
echo "Task repo created successfully!"

echo "==============================="
echo "Now when Enter will Redirect you to the github to install app"
echo "You Install it and Select a Repo Called Linux-25-Training:"
read key
xdg-open "https://github.com/apps/task-handler"

gh issue comment 1 --repo Open-Source-Community/Linux-Tasks --body "Get Tasks"
