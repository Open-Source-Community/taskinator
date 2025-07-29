#-------------------------GRADE SCRIPT -------------------------

# A script to auto-grade OSC Linux committee tasks

# Input: CSV file with the following schema:
# "Email Address,Full name,Link to Task repo"

# Output: CSV file with the following schema:
# "Name,Email,Github Link,Result"

# Result can take three values:
# CORRECT
# INCORRECT
# NOTSUBMITTED

# Hardcoded Arguments
test_script="demo/test.sh"
source_file="demo/data.csv"
target_file="demo/output.csv"
task_prefix="Task_"
result_file="Result.md"

# Color constants
YELLOW="\033[33m"
NORMAL="\033[0;39m"
RED="\033[31m"
GREEN="\033[32m"
bold=$(tput bold)
normal=$(tput sgr0)

# Helper functions
file_exists() {
    [[ -f "$1" ]] || { echo "Required file not found: $1"; return 1; }
}

dir_exists() {
    [[ -d "$1" ]] || { echo "Required directory not found: $1"; return 1; }
}

# Function definitions

test_repo() {
    name=$(echo "$entry" | cut -d',' -f2)
    email=$(echo "$entry" | cut -d',' -f1)
    github_link=$(echo "$entry" | cut -d',' -f3 | tr -d '\r' | sed 's/[[:space:]]*$//')
    reponame="entry_$student"
    echo -e "${bold}Name:${normal} $name"
    echo -e "${bold}Email:${normal} $email"
    echo -e "${bold}GitHub Link:${normal} $github_link"
    echo -e "${bold}Repo Name:${normal} $reponame"

    git clone "$github_link" "$reponame" > /dev/null
    cd "$reponame"
    # Run test script
    run_test;
    test_status=$?
    if [ $test_status = 0 ]; then
        echo -e "${bold}${GREEN}Solution is correct${NORMAL}${normal}"
        result=CORRECT
    elif [ $test_status = 1 ]; then
        echo -e "${bold}${YELLOW}Solution is not correct${NORMAL}${normal}"
        result=INCORRECT
    else
        echo -e "${bold}${YELLOW}Not submitted/not following guidelines${NORMAL}${normal}"
        result=NOTSUBMITTED
    fi
}

run_test() {
    dir_exists $task_dir
    if [ $? != 0 ]; then
        echo -e "${bold}${RED}Session $task_number folder not found${NORMAL}${normal}"
        return 3
    else
        echo -e "${GREEN}Session folder found!${NORMAL} Navigating..."
        cd "$task_dir"
        "$root/$test_script"
        return $?
    fi
}

save_result() {
    echo "$name,$email,$github_link,$result" >>"$root/$target_file"
}

post_result(){
    {
        echo "# Task $task_number Result"
        echo "**Time of grading:** $(TZ=Africa/Cairo date '+%A, %B %d, %Y, %I:%M %p')"
        echo ""
        echo "**Result:** $result"
    } >> "$result_file"

    git add "$result_file" > /dev/null
    git commit -m "Posted task results" > /dev/null
    git push > /dev/null 
}

next_repo() {
    cd "$root"
    [ -n "$reponame" ] && rm -rf "$reponame"
}

init(){
    task_number=$1
    root=$(pwd)
    task_dir="$task_prefix""$task_number"
    echo "Name,Email,Github Link,Result" >"$target_file"
    echo "Grading ${bold}task $task_number${normal}..."

    if [ ! -e $source_file ]; then
        echo -e "${bold}${RED}Data sheet not found!${NORMAL}${normal}"
        exit 1
    fi

    repos_number=$(($(wc -l <"$source_file") - 1)) # subtract header
    echo "${bold}Number of repos: $repos_number${normal}"

    if [ ! -e $test_script ]; then
        echo -e "${bold}${RED}Test script not found!${NORMAL}${normal}"
        exit 1
    fi
}

# Main

init $1

for student in $(seq 1 "$repos_number"); do
    entry=$(sed -n $((student + 1))p "$source_file")
    echo -e "Grading repo ${bold}$((student))/$repos_number${normal}"
    test_repo
    save_result
    # post_result
    next_repo
    echo -e "-------------------------------)"
done

echo -e "Grading complete! Results in ${bold}$target_file${normal}"
cat "$target_file"
exit 0
