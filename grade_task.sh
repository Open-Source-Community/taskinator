#!/bin/bash

# Based on https://github.com/Badr-1/scripts/tree/main/testing

# A script to auto-grade OSC Linux committee tasks

# Requirements
# Git
# bat (for syntax-highlighted file viewing)
# lsd (for enhanced directory listing)
# fzf (for interactive file selection)
# Bash

# Input: tsv file with the following schema:
# | Timestamp | Email Address	| Full name | Link to Task repo |

# Output: tsv file with the following schema:
# "| Name | Email | Github Link | Result |"

# Result can take three values:
# CORRECT
# INCORRECT
# NOTSUBMITTED

# Hardcoded Arguments
task=3
solution="commands.sh"
test_script="demo/test.sh"
source="demo/sample.tsv"
target="demo/output.tsv"

# Color constants
YELLOW="\033[33m"
NORMAL="\033[0;39m"
RED="\033[31m"
GREEN="\033[32m"
bold=$(tput bold)
normal=$(tput sgr0)

# Function definitions
run_test() {
    source "$root/$test_script" "$solution"
    return $?
}

next_repo() {
    cd "$root"
    [[ -n "$reponame" ]] && rm -rf "$reponame"
    read -p "${bold}Press Enter to move to the next repo ${normal}"
}

write_result() {
    cd "$root"
    echo -ne "Result: "
    if [[ $result = "NOTSUBMITTED" ]]; then
        echo -e "${RED}Not Submitted${NORMAL}"
    elif [[ $result = "INCORRECT" ]]; then
        echo -e "${YELLOW}Incorrect${NORMAL}"
    elif [[ $result = "CORRECT" ]]; then
        echo -e "${GREEN}Correct${NORMAL}"
    fi
    echo -e "$name\t$email\t$github_link\t$result" >>"$target"
}

test_repo() {
    #timestamp=$(echo "$entry" | cut -f1)
    result=NOTSUBMITTED
    name=$(echo "$entry" | cut -f3)
    email=$(echo "$entry" | cut -f2)
    github_link=$(echo "$entry" | cut -f4)
    reponame="entry_$student"
    echo -e "${bold}Name:${normal} $name"
    echo -e "${bold}Email:${normal} $email"
    echo -e "${bold}GitHub Link:${normal} $github_link"
    echo -e "${bold}Repo Name:${normal} $reponame"

    git clone "$github_link" "$reponame"

    lsd "$reponame"
    read -rp "${bold}Pause to fix the repo if needed. Press Enter to continue${normal}"

    # Check if task folder is present
    path="$(find "$reponame" -maxdepth 1 -type d | grep "$task")"

    if [[ ! -n $path ]]; then
        echo -e "${bold}${RED}Session $task folder not found${NORMAL}${normal}"
        result=NOTSUBMITTED
        write_result
        return 1
    fi

    echo -e "${GREEN}Session folder found!${NORMAL} Navigating..."
    cd "$path"

    # Check if solution file is present
    if [[ -f "$solution" ]]; then
        echo -e "${GREEN}Solution file found!${NORMAL}"
    else
        lsd
        read -rp "${bold}Does the solution exist? (y/n): ${normal}" answer
        if [[ $answer == 'y' ]]; then
            wrong_name=$(find . -type f | fzf)
            mv "$wrong_name" "$solution"
        else
            echo -e "${bold}${RED}$solution not found${NORMAL}${normal}"
            result=NOTSUBMITTED
            write_result
            return 1
        fi
    fi

    # Run test script
    if run_test; then
        echo -e "${bold}${GREEN}Solution auto-graded as correct${NORMAL}${normal}"
        result=CORRECT
        write_result
        return 0
    else
        # Print solution to check manually
        echo -e "${bold}${YELLOW}Auto-grading failed!${NORMAL}${normal}"
        read -rp "${bold}Press Enter to grade manually ${normal}" answer

        bat -P $solution
        read -rp "${bold}Is the solution correct? (y/n): ${normal}" answer
        if [[ $answer == 'y' ]]; then
            echo -e "${bold}${GREEN}Solution manually graded as correct${NORMAL}${normal}"
            result=CORRECT
            write_result
            return 0

        else
            echo -e "${bold}${YELLOW}$solution is not correct${NORMAL}${normal}"
            result=INCORRECT
            write_result
            return 1
        fi
    fi

}

# Main

echo -e "Name\tEmail\tGithub Link\tResult" >"$target"

echo "Grading ${bold}task $task${normal}..."

if [[ ! -e $source ]]; then
    echo -e "${bold}${RED}Data sheet not found!${NORMAL}${normal}"
    exit 1
fi

root=$(pwd)

repos_number=$(wc -l <"$source")
echo "${bold}Number of repos: $repos_number${normal}"

if [[ ! -e $test_script ]]; then
    echo -e "${bold}${RED}Test script not found!${NORMAL}${normal}"
    exit 1
fi

read -p "${bold}Press Enter to start testing${normal}"

for student in $(seq 1 "$repos_number"); do
    entry=$(sed -n $((student + 1))p $source)
    echo -e "Grading repo ${bold}$((student))/$repos_number${normal}"
    test_repo
    next_repo
    echo -e "-------------------------------)"
done

echo -e "Grading complete! Results in ${bold}$target${normal}"
bat $target
exit 0
