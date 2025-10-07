#!/bin/bash

# Task #N Testing Script
# Created by: [Your Name Here]

# Task status:
readonly CORRECT=0
readonly INCORRECT=1
readonly ERROR=2

# Write your code between START and END lines.
# Do not remove any code or comments.
# You can add any notes here if you'd like.

# /--------- Helper Functions ------------/
file_exists() {
    [[ -f "$1" ]] || { echo "Required file not found: $1"; return 1; }
}

dir_exists() {
    [[ -d "$1" ]] || { log_error "Required directory not found: $1"; return 1; }
}

# /--------- Test Setup ------------/
setup() {
    # Include any starter code needed to execute the test. Assume you are inside the task repo (github-username/repo-name) and move from there.
    # If you fail to find a folder that should've been there, or fail to set up for grading, return 3
    echo "Setting up task environment..."
    # START
    :
    # END
}

# /-------- Test Execution ---------/
test() {
    echo "Executing test..."
    # Grade the actual task
    # Return 1 if the task is correct
    # Return 2 if the task is incorrect
    # START
    :
    # END
}

# /--------- Test Cleanup ----------/
cleanup() {
    echo "Cleaning up..."
    # If you need to do any cleanup after grading the task, do it here
    # START
    :
    # END
}

# /------------- Main -------------/
setup || exit $ERROR
test
RESULT=$?
cleanup
exit $RESULT