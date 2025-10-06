#!/bin/bash

# Prerequistes: gh, git

# Modifiable variables - set per your usage
collaborators=('thisisamna' 'hadeer-r' 'HabibaYossre' 'Momen-MKadry')
repo_name="Linux-25-Training"
task_handler_app="https://github.com/apps/task-handler"

# Fetching the student's username
username=$(gh api user --jq '.login')

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
else
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
fi

echo "==============================="
echo "You will be redirected to GitHub to install the automation app."
echo "1. Click 'Configure'"
echo "2. Choose your GitHub account and click 'Install'"
echo "3. Change repository access to 'Only select repositories' and choose $repo_name"
echo "4. Click 'Save'"
echo "Press Enter to open the link in your browser: https://github.com/apps/task-handler"
read key
xdg-open "$task_handler_app" > /dev/null

echo "Repo initialization completed!"