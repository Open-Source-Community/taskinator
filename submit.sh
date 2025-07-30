#!/bin/bash

# Script to automatically upload task
# This will submit the task in the folder it was executed in

test_file="test.sh"

# Run the test script if provided with the task
run_test() {
	echo "Running test script..."
	./"$test_file"
	if [ $? != 0 ]; then
		echo "Test failed. Do you still want to submit? (y\N)"
		read -s -n1 choice
		if ! [ $choice == 'y' ] || [ $choice == 'Y' ]; then
			echo "Exiting without submitting task..."
			exit 0
		else
			echo "Continuing..."
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
		git add . &> /dev/null 
		git commit -m "Task submission." &> /dev/null 
		git push &> /dev/null
		echo "Task submitted successfully!"

	else
		echo "No changes since last push."
	fi
	return 0
}

# Main
if [ -f "$test_file" ]; then
	run_test
fi
upload_task
