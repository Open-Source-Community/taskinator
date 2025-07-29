#!/bin/bash

file_exists() {
    [[ -f "$1" ]] || { echo "Required file not found: $1"; return 1; }
}

file_exists hi.txt # Passing test
# file_exists none.txt # Failing test
# exit 0 # blind passing test
# exit 1 # blind failing test
exit $?