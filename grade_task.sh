#!/bin/bash

# A script to auto-grade OSC Linux committee tasks
# Output: CSV file with the following schema:
# "GitHub username,task repo link,result"
# Result can take three values:
# CORRECT - 0
# INCORRECT - 1
# NOTSUBMITTED (or error) - 2

# Modifiable Variables 
results_summary="./results.csv"
result_file="Result.md"

# Script start

readonly task_to_grade=$1
# This is the comment text to the issue
# Might parse it over there and ensure its a number, but for now handling it within the get_all_tasks function
echo "🗨️  Triggered by comment: '$1'"
echo "----------------------------------------"

repos_dir="./student_repos"
github_api_url="https://api.github.com"
root=""
tasks=()

export TERM=xterm
# Color constants
yellow="\033[33m"
normal="\033[0;39m"
red="\033[31m"
green="\033[32m"
bold=$(tput bold)
normal=$(tput sgr0)

# Helper functions
file_exists() {
    [[ -f "$1" ]] || { echo "Required file not found: $1"; return 1; }
}

dir_exists() {
    [[ -d "$1" ]] || { echo "Required directory not found: $1"; return 1; }
}

error_exit() {
    echo "ERROR: $1"
    exit 1
}

check_env() {
    if [[ -z "$APP_ID" || -z "$APP_PRIVATE_KEY" ]]; then
        error_exit "APP_ID and APP_PRIVATE_KEY environment variables are required"
    fi
    # Configure git (using bot identity)
    git config --global user.name "Task Grading Bot"
    git config --global user.email "bot@osc.com"
}

generate_jwt() {
    local app_id="$1"
    local private_key="$2"
    
    local header='{"alg":"RS256","typ":"JWT"}'
    local header_b64=$(echo -n "$header" | base64 -w 0 | tr -d '=' | tr '/+' '_-')
    
    local now=$(date +%s)
    local exp=$((now + 600))  # 10 minutes
    local payload="{\"iat\":$now,\"exp\":$exp,\"iss\":\"$app_id\"}"
    local payload_b64=$(echo -n "$payload" | base64 -w 0 | tr -d '=' | tr '/+' '_-')
    
    local signature_input="${header_b64}.${payload_b64}"
    
    local temp_key=$(mktemp)
    echo "$private_key" > "$temp_key"
    
    local signature=$(echo -n "$signature_input" | openssl dgst -sha256 -sign "$temp_key" | base64 -w 0 | tr -d '=' | tr '/+' '_-')
    
    rm "$temp_key"
    
    echo "${signature_input}.${signature}"
}

api_request() {
    local method="$1"
    local url="$2" 
    local token="$3"
    local data="$4"
    
    local temp_headers=$(mktemp)
    local curl_args=(-X "$method" -H "Authorization: token $token" -H "Accept: application/vnd.github.v3+json" -D "$temp_headers")
    
    if [[ -n "$data" ]]; then
        curl_args+=(-H "Content-Type: application/json" -d "$data")
    fi
    
    local response=$(curl -s "${curl_args[@]}" "$url")
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "${curl_args[@]}" "$url")
    
    # Check rate limits
    local remaining=$(grep -i "x-ratelimit-remaining:" "$temp_headers" | cut -d: -f2 | tr -d ' \r')
    local reset=$(grep -i "x-ratelimit-reset:" "$temp_headers" | cut -d: -f2 | tr -d ' \r')
    
    rm "$temp_headers"
    
    if [[ -n "$remaining" && "$remaining" -lt 100 ]]; then
        local wait_time=$((reset - $(date +%s) + 10))
        echo "⚠️ Rate limit low ($remaining remaining). Waiting $wait_time seconds..."
        sleep $wait_time
    fi
    
    if [[ "$http_code" == "403" ]]; then
        echo "🚫 Rate limited. Waiting 60 seconds..."
        sleep 60
        # Retry once
        curl -s "${curl_args[@]}" "$url"
    else
        echo "$response"
    fi
}

get_installations() {
    local jwt_token="$1"
    local page=1
    local installations="[]"

    while :; do
        local response=$(curl -s \
            -H "Authorization: Bearer $jwt_token" \
            -H "Accept: application/vnd.github.v3+json" \
            "$github_api_url/app/installations?per_page=100&page=$page")

        if [[ "$(echo "$response" | jq 'length')" -eq 0 ]]; then
            break
        fi

        installations=$(jq -s 'add' <(echo "$installations") <(echo "$response"))
        ((page++))
    done

    echo "$installations"
}

get_installation_token() {
    local installation_id="$1"
    local jwt_token="$2"
    
    local response=$(curl -s -X POST \
        -H "Authorization: Bearer $jwt_token" \
        -H "Accept: application/vnd.github.v3+json" \
        "$github_api_url/app/installations/$installation_id/access_tokens")
    
    echo "$response" | jq -r '.token'
}

get_installation_repos() {
    local token="$1"
    
    local response=$(api_request "GET" "$github_api_url/installation/repositories" "$token")
    echo "$response"
}

get_all_student_repos() {
    local jwt_token="$1"
    local student_repos=()
    local repo_pattern="Linux-25-Training"
    
    local installations=$(get_installations "$jwt_token")
    local installation_count=$(echo "$installations" | jq length)

    for ((i=0; i<installation_count; i++)); do
        local installation=$(echo "$installations" | jq ".[$i]")
        local installation_id=$(echo "$installation" | jq -r '.id')

        local token=$(get_installation_token "$installation_id" "$jwt_token")
        
        if [[ "$token" == "null" || -z "$token" ]]; then
            echo "Failed to get token for installation $installation_id" >&2
            continue
        fi
        
        local repos=$(get_installation_repos "$token")
        local repo_count=$(echo "$repos" | jq '.repositories | length')
        
        for ((j=0; j<repo_count; j++)); do
            local repo=$(echo "$repos" | jq ".repositories[$j]")
            local repo_full_name=$(echo "$repo" | jq -r '.full_name')
            local clone_url=$(echo "$repo" | jq -r '.clone_url')

            if [[ $repo_full_name =~ $repo_pattern ]]; then
                student_repos+=("$repo_full_name|$token|$clone_url")
            fi
        done
    done
    
    printf '%s\n' "${student_repos[@]}"
}

get_all_tasks() {
    if [[ -n "$1" && "$1" =~ ^[0-9]+$ ]]; then
        local task_name="Task-$1"
        if [[ -d "$task_name" ]]; then
            tasks=("$task_name")
            echo "Grading specific task: $task_name"
        else
            error_exit "Task directory '$task_name' not found for task number $1"
        fi
    else
        # Not a number or empty, grade all tasks
        tasks=($(find . -maxdepth 1 -type d -name 'Task*' -printf '%f\n' | sort))
        echo "Grading all ${#tasks[@]} tasks: ${tasks[*]}"
    fi
}
commit_and_push() {
    echo "DEBUG: commit_and_push called from $(pwd)"
    echo "DEBUG: Looking for $result_file"
    find . -name "Result.md" -type f
    echo "DEBUG: Git status:"
    git status --porcelain
    local auth_url="$1"
    local repo_full_name="$2"
    
    git config user.name "Task Grading Bot"
    git config user.email "bot@osc.com"
    
    git remote set-url origin "$auth_url"
    
    # Add all changes
    git add .
    git diff --staged --name-only
    # Check if there are changes to commit
    if git diff --staged --quiet; then
        echo "    ↳ No changes to commit"
        return 1
    fi
    
    # Commit changes
    local commit_msg="Task Grading Results - $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$commit_msg"
    
    # Push changes
    echo "    📤 Pushing changes..."
    if git push origin HEAD; then
        echo "    ✅ Changes pushed successfully to $repo_full_name"
        return 0
    else
        echo "    ❌ Failed to push changes to $repo_full_name"
        return 1
    fi
}

run_test() {
    local test_script="$1"
    if [[ ! -f "$test_script" ]]; then
        echo "Test script not found: $test_script" >&2
        return 3
    fi
    
    chmod +x "$test_script"
    
    echo "Running test script: $test_script"
    if bash "$test_script" > "$result_file" 2>&1; then
        return 0
    else
        local exit_code=$?
        echo "Test failed with exit code: $exit_code" >&2
        return $exit_code
    fi
}

add_to_summary() {
    local username="$1"
    local repo_url="$2"
    local task="$3"
    local result="$4"
    local comments="$5"
    
    echo "$username,$repo_url,$result,$comments" >> "$root/${task}/$results_summary"
}

process_repo() {
    local repo_data="$1"
    
    local repo_full_name=$(echo "$repo_data" | cut -d'|' -f1)
    local token=$(echo "$repo_data" | cut -d'|' -f2)
    local clone_url=$(echo "$repo_data" | cut -d'|' -f3)
    
    local username=$(echo "$repo_full_name" | cut -d'/' -f1)
    local repo_dir="$root/$repos_dir/$username"

    echo "${bold}${yellow}Processing repo: $repo_full_name${normal}${normal}"
    
    # Create authenticated URL
    local auth_url="https://x-access-token:${token}@github.com/${repo_full_name}.git"
    
    cd "$root/$repos_dir"
    echo "In repos dir:"
    pwd

    # Clone repository
    echo "  📥 Cloning repository..."
    if ! git clone --depth 1 "$auth_url" "$username" >/dev/null; then
        echo "  ❌ Failed to clone $repo_full_name"
        # Add failed clone entries to summary for all tasks
        for task in "${tasks[@]}"; do
            add_to_summary "$username" "$clone_url" "$task" "NOTSUBMITTED" "Failed to clone repository"
        done
        return 1
    fi
    
    echo "  ✅ Successfully cloned $repo_full_name"
    
    cd "$repo_dir"
    echo "In $repo_full_name's dir:"
    pwd


    # Process each task
    for task in "${tasks[@]}"; do
        echo "    🧪 Testing task: $task"
        
        local task_dir="$repo_dir/$task"
        local result="NOTSUBMITTED"
        local comments=""
        
        if [[ ! -d "$task_dir" ]]; then
            echo "    ❌ Task directory not found: $task_dir"
            comments="Task directory not found"
        else
            # Change to task directory
            cd "$task_dir"
            echo "In task dir:"
            pwd

            if [[ -f $result_file ]]; then
                local line_count
                line_count=$(wc -l < "$result_file")
                local get_result
                get_result=$(grep -o -i '\<correct\>' "$result_file")
                if [[ $get_result == "CORRECT" ]]; then
                    echo "    🎯 Found previous CORRECT result, skipping test"
                    result="CORRECT"
                else
                    rm $result_file
                fi
                
            fi

            if [[ ! -f $result_file ]]; then
                local test_script
                test_script="$root/$task/$(tr '[:upper:]-' '[:lower:]_' <<< "$task")_test.sh"
                if [[ -z "$test_script" ]]; then
                    echo "    ❌ No test script found in task directory"
                    comments="No test script found"
                else
                    
                    # Run the test
                    local test_status
                    if run_test "$test_script"; then
                        test_status=0
                    else
                        test_status=$?
                    fi
                    
                    # Determine result
                    case $test_status in
                        0)
                            result="CORRECT"
                            echo "    ✅ Solution is correct"
                            ;;
                        1)
                            result="INCORRECT"
                            echo "    ❌ Solution is incorrect"
                            ;;
                        *)
                            result="NOTSUBMITTED"
                            comments="Test execution failed (exit code: $test_status)"
                            echo "    ❌ $comments"
                            ;;
                    esac
                fi

                local temp_results=$(mktemp)

                # Append result information to Result.md
                {
                    echo ""
                    echo "---"
                    echo "# Task Grading Result"
                    echo ""
                    echo "- **Time of grading:** $(TZ=Africa/Cairo date '+%A, %B %d, %Y, %I:%M %p')"
                    echo ""
                    echo "- **Task:** $task"
                    echo ""
                    echo "- **Result:** $result"
                    echo ""
                    if [[ -n "$comments" ]]; then
                        echo "- **Comments:** $comments"
                    fi
                    echo ""
                    echo "Logs:"
                    echo '```bash' # Single quotes
                    cat "$result_file" 
                    echo '```'
                } > "$temp_results"

                mv "$temp_results" "$result_file"
            fi
            # Find test script
            
            
        fi

        #logging start
        pwd
        cat "$result_file"
        #logging end
        
        # Go back to repo root
        cd "$repo_dir"
        
        # Add to summary
        add_to_summary "$username" "$clone_url" "$task" "$result" "$comments"
    done
    
    # Commit and push results
    echo "  🔄 Committing and pushing results..."
    commit_and_push "$auth_url" "$repo_full_name"

    # Go back to repos directory
    cd "$root/$repos_dir"

    # Remove repository directory
    echo "  🗑️ Cleaning up repository directory..."
    rm -rf "$repo_dir"
    # Go back to root

    cd "$root"
    echo "  ✅ Finished processing $repo_full_name"
}

commit_summary() {
    
    # Add and commit results summary
    git add "$results_summary"
    
    if git diff --staged --quiet; then
        echo "No changes to commit for results summary"
        return 0
    fi
    
    local commit_msg="Update grading results summary - $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$commit_msg"
    
    echo "✅ Results summary committed to repository"
}

# ---------- Main Execution -------------
Main(){
    check_env

    root=$(pwd)
    get_all_tasks "$task_to_grade"

    if [[ ${#tasks[@]} -eq 0 ]]; then
        error_exit "No tasks found. Make sure Task* directories exist."
    fi
    
    echo "${bold}${green}Found tasks: ${tasks[*]}${normal}${normal}"

    # Delete old results
    for task in "${tasks[@]}"; do
        if [[ -f "$task/$results_summary" ]]; then
            rm "$task/$results_summary"
        fi
    done

    # Generate JWT token
    local jwt_token=$(generate_jwt "$APP_ID" "$APP_PRIVATE_KEY")
    if [[ -z "$jwt_token" ]]; then
        error_exit "Failed to generate JWT token"
    fi
    
    # Create repos directory
    mkdir -p "$repos_dir"
    
    # Get all student repositories
    echo "${bold}${yellow}Fetching student repositories...${normal}${normal}"
    local repo_data
    repo_data=$(get_all_student_repos "$jwt_token")
    
    if [[ -z "$repo_data" ]]; then
        error_exit "No student repositories found"
    fi
    
    local total_repos=$(echo "$repo_data" | wc -l)
    echo "${bold}${green}Found $total_repos student repositories${normal}${normal}"
    
    # Process each repository
    local count=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        
        ((count++))

        
        echo "${bold}Processing repository $count/$total_repos${normal}"
        
        process_repo "$line"
        
    done <<< "$repo_data"
    
    # Delete the parent repos directory
    echo ""
    echo "${bold}${yellow}Cleaning up repositories directory...${normal}${normal}"
    rm -rf "$repos_dir"
    
    # Commit results summary
    echo ""
    echo "${bold}${yellow}Committing results summary...${normal}${normal}"
    commit_summary
    
    echo ""
    echo "${bold}${green}All repositories processed successfully!${normal}${normal}"
    echo "${bold}Results summary saved to: $results_summary${normal}${normal}"
}

Main "$@"
