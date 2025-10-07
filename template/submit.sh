#!/bin/bash

# Script to automatically upload task
# This will submit the task in the folder it was executed in

test_file="check.sh"

# Run the test script if provided with the task
run_test() {
	echo "Running test script..."
	./"$test_file"
	if [ $? != 0 ]; then
		echo "Test failed. Do you still want to submit? (y/N)"
		read -s -n1 choice
		if  [ $choice == 'y' ] || [ $choice == 'Y' ]; then
			echo "Continuing..."
		else
			echo "Exiting without submitting task..."
			exit 0
		fi
	fi
}

# Add, commit and push changes
upload_task () {
	local git_branch=$(git branch --show-current)
	if [ "$git_branch" != 'master' ] && [ "$git_branch" != 'main' ]; then
		echo "Error: Wrong branch! Ensure that you are on main or master."
		exit 1
	fi
	if [ "$(git status -s | wc -l )" != 0 ]; then
		git add . > /dev/null 
		git commit -m "Task submission." &> /dev/null 
		git push > /dev/null || return 1
		echo "Task submitted successfully!"

	elif [ "$(git rev-list --count @{u}..HEAD 2>/dev/null)" -gt 0 ]; then		git push > /dev/null || return 1
		# unpushed commits exist
		git push
	else
		echo "No changes since last push."
	fi
	return 0
}

# Main
echo "[1/3] Fetching changes..."
git pull > /dev/null || exit 2
if [ -f "$test_file" ]; then
echo "[2/3] Testing..."
	run_test
fi
echo "[3/3] Uploading task..."

upload_task || echo "Error in upload, please message support"

