#!/bin/bash

# only run once
# by members
# prerequistes: gh, git

# gh username
username=$(gh api user --jq '.login')

# collaborators
collaborators=('thisisamna' 'hadeer-r' 'HabibaYossre' 'Momen-MKadry')

# repo name
repo_name="Linux-25-Training"


# local repo setup
git init -b main $repo_name
cd $repo_name
git commit --allow-empty -m "repository setup"

# remote repo setup
gh repo create $repo_name --private --source=. --remote=origin
git push -u origin main

# add collaberators
for c in "${collaborators[@]}"
do
	gh api -X PUT "/repos/$username/$repo_name/collaborators/$c" -f permission=write >> /dev/null
done

echo "Task repo created successfully!"
