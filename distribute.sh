#!/bin/bash

github_api_url="https://api.github.com"
tasks_dir="."
repos_dir="./student_repos"  # Local directory for cloned repos
test_pattern=".*test.sh"
result_pattern=".*results.csv"
solution_pattern=".*solution.*"

error_exit() {
    echo "ERROR: $1"
    exit 1
}

check_env() {
    if [[ -z "$APP_ID" || -z "$APP_PRIVATE_KEY" ]]; then
        error_exit "APP_ID and APP_PRIVATE_KEY environment variables are required"
    fi
}

# Generate JWT token for GitHub App
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

# Make authenticated API request
api_request() {
    local method="$1"
    local url="$2"
    local token="$3"
    local data="$4"
    
    local curl_args=(-X "$method" -H "Authorization: token $token" -H "Accept: application/vnd.github.v3+json")
    
    if [[ -n "$data" ]]; then
        curl_args+=(-H "Content-Type: application/json" -d "$data")
    fi
    
    curl -s "${curl_args[@]}" "$url"
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

        # If the response is empty array, break
        if [[ "$(echo "$response" | jq 'length')" -eq 0 ]]; then
            break
        fi

        # Merge current page with accumulated installations
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
        local account_login=$(echo "$installation" | jq -r '.account.login')

        local token=$(get_installation_token "$installation_id" "$jwt_token")
        
        if [[ "$token" == "null" || -z "$token" ]]; then
            echo "Failed to get token for installation $installation_id" 
            continue
        fi
        
        # Get repositories for this installation
        local repos=$(get_installation_repos "$token")
        local repo_count=$(echo "$repos" | jq '.repositories | length')
        
        local student_count=0
        for ((j=0; j<repo_count; j++)); do
            local repo=$(echo "$repos" | jq ".repositories[$j]")
            local repo_name=$(echo "$repo" | jq -r '.name')
            local repo_full_name=$(echo "$repo" | jq -r '.full_name')
            local clone_url=$(echo "$repo" | jq -r '.clone_url')
            local is_private=$(echo "$repo" | jq -r '.private')

            if [[ $repo_full_name =~ $repo_pattern ]]; then
                student_repos+=("$repo_full_name:$token:$clone_url")
                ((student_count++))
            fi
        done
    done
    
    printf '%s\n' "${student_repos[@]}"
}

get_task_files() {
    if [[ ! -d "$tasks_dir" ]]; then
        error_exit "Tasks directory '$tasks_dir' not found"
    fi
    
    find "$tasks_dir" -type f ! -name ".*" -print
}

# Clone or pull repository
clone_or_pull_repo() {
    local repo_full_name="$1"
    local token="$2"
    local clone_url="$3"
    local repo_name=$(basename "$repo_full_name")
    local repo_dir="$repos_dir/$repo_name"
    
    # Create repos directory if it doesn't exist
    mkdir -p "$repos_dir"
    
    # Construct authenticated URL properly
    local auth_url="https://x-access-token:${token}@github.com/${repo_full_name}.git"
    
    if [[ -d "$repo_dir" ]]; then
        (
            cd "$repo_dir" || exit 1
            # Set the remote URL with token for pulling
            git remote set-url origin "$auth_url"
            # Try main branch first, then master
            git pull origin main 2>/dev/null || git pull origin master 2>/dev/null
        )
        if [[ $? -ne 0 ]]; then
            echo "    ⚠️  Pull failed, trying fresh clone..."
            rm -rf "$repo_dir"
            if ! git clone "$auth_url" "$repo_dir"; then
                echo "  ✗ Failed to clone $repo_full_name"
                return 1
            fi
        fi
    else
        if ! git clone "$auth_url" "$repo_dir"; then
            echo "  ✗ Failed to clone $repo_full_name"
            return 1
        fi
    fi
    
    if [[ ! -d "$repo_dir" ]]; then
        echo "  ✗ Failed to access $repo_full_name"
        return 1
    fi
    
    echo "$repo_dir"
}

# Copy tasks to repository with exclusion check
copy_tasks_to_repo() {
    local repo_dir="$1"
    local repo_full_name="$2"
    local task_files=("${@:3}")
    local changes_made=false
    local files_processed=0
    local files_updated=0
    local files_created=0
    local files_skipped=0
    echo "++++++++++++++copying Tasks to Repo++++++++++++++"
    echo "  📋 Processing tasks for $(basename "$repo_full_name")..."
    
    for task_file in "${task_files[@]}"; do

        local relative_path="${task_file#$tasks_dir/}"

        relative_path="${relative_path#/}"
        local dest_path="$repo_dir/$relative_path"
        
        ((files_processed++))
        
        # Exclude solution file
        if [[ -f "$dest_path" ]]; then
            if [[ "$relative_path" =~ $solution_pattern ]]; then 
                ((files_skipped++))
                echo "    ↳ $relative_path - Skipped solution file update"
                continue
            fi      

            if [[ "$relative_path" =~ $script_extract ]]; then 
                ((files_skipped++))
                echo "    ↳ $relative_path - Skipped solution file update"
                continue
            fi   

            if [[ "$relative_path" =~ $script_Sum ]]; then 
                ((files_skipped++))
                echo "    ↳ $relative_path - Skipped solution file update"
                continue
            fi      

        fi
         
        # Exclude test file
        if [[ "$relative_path" =~ $test_pattern ]]; then 
            ((files_skipped++))
            echo "    ↳ $relative_path - Skipped test file upload"
            continue
        fi

        # Exclude result file
        if [[ "$relative_path" =~ $result_pattern ]]; then 
            ((files_skipped++))
            echo "    ↳ $relative_path - Skipped result file upload"
            continue
        fi

        mkdir -p "$(dirname "$dest_path")"
        
        # Check if file exists and compare content
        if [[ -f "$dest_path" ]]; then
            if cmp -s "$task_file" "$dest_path"; then
                echo "    ↳ $relative_path - No changes needed"
            else
                echo "    ✓ $relative_path - Updated"
                cp "$task_file" "$dest_path"
                changes_made=true
                ((files_updated++))
            fi
        else
            echo "    ✓ $relative_path - Created"
            cp "$task_file" "$dest_path"
            changes_made=true
            ((files_created++))
        fi
        echo "dest Path: $dest_path"
        echo "task file: $task_file"
        echo "relative path: $relative_path"
    done
    echo "    📊 Summary: $files_processed processed, $files_created created, $files_updated updated, $files_skipped skipped"
    if [[ "$changes_made" == true ]]; then
        return 0
    else
        return 1
    fi
    
}

# Commit and push changes
commit_and_push() {
    local repo_dir="$1"
    local repo_full_name="$2"
    local token="$3"  # Add token parameter
    
    cd "$repo_dir" || return 1
    
    # Configure git if needed (using bot identity)
    git config user.name "Task Distribution Bot"
    git config user.email "bot@osc.com"
    
    # Set authenticated remote URL for pushing
    local auth_url="https://x-access-token:${token}@github.com/${repo_full_name}.git"
    git remote set-url origin "$auth_url"
    
    # Add all changes
    git add .
    
    # Check if there are changes to commit
    if git diff --staged --quiet; then
        echo "    ↳ No changes to commit"
        return 1
    fi
    
    # Show what will be committed
    local added_files=$(git diff --staged --name-only | wc -l)
    echo "    📝 Committing $added_files file(s)"
    
    # Commit changes
    local commit_msg="Add/Update tasks - $(date '+%Y-%m-%d %H:%M:%S')"
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

# Main distribution function
distribute_tasks() {
    echo "🚀 Starting task distribution..."
    
    # Check environment
    check_env
    
    local jwt_token=$(generate_jwt "$APP_ID" "$APP_PRIVATE_KEY")
    echo "🔑 JWT Token generated successfully."
    
    echo "📚 Getting student repositories..."
    local student_repos_raw=$(get_all_student_repos "$jwt_token")
    local student_repos=()
    
    while IFS= read -r line; do
        [[ -n "$line" ]] && student_repos+=("$line")
    done <<< "$student_repos_raw"
    
    if [[ ${#student_repos[@]} -eq 0 ]]; then
        error_exit "No student repositories found!"
    fi
    
    for repo in "${student_repos[@]}"; do
        local repo_name="${repo%%:*}"
        echo "Found student repository: $repo_name"
    done
    
    echo "✅ Student repositories fetched successfully. Total: ${#student_repos[@]}"
    
    echo "📁 Getting task files..."
    local task_files=()
    local task_pattern="Task-[0-9]+"
    
    while IFS= read -r -d '' file; do
        if [[ $file =~ $task_pattern ]]; then
            task_files+=("$file")
        fi
    done < <(get_task_files | tr '\n' '\0')
    
    for f in "${task_files[@]}"; do
        echo "Found task file: $f"
    done
    
    if [[ ${#task_files[@]} -eq 0 ]]; then
        error_exit "No task files found!"
    fi
    
    echo "✅ Task files fetched successfully. Total: ${#task_files[@]}"
    
    # Main distribution loop
    local updated_repos=0
    local unchanged_repos=0
    local failed_repos=0
    local total_repos=${#student_repos[@]}
    
    echo "🔄 Starting distribution to $total_repos repositories..."
    
    for repo_info in "${student_repos[@]}"; do
        local repo_full_name="${repo_info%%:*}"
        local remaining="${repo_info#*:}"
        local token="${remaining%%:*}"
        local clone_url="${remaining#*:}"
        
        echo ""
        echo "📂 Processing repository: $repo_full_name"
        
        # Clone or pull repository
        local repo_dir
        repo_dir=$(clone_or_pull_repo "$repo_full_name" "$token" "$clone_url")
        


        if [[ ! -d "$repo_dir" ]]; then
            echo "  ❌ Failed to access repository"
            ((failed_repos++))
            continue
        fi
        
        # Copy tasks to repository

        if copy_tasks_to_repo "$repo_dir" "$repo_full_name" "${task_files[@]}"; then
            echo "  ✅ Changes made to $repo_full_name"
            commit_and_push "$repo_dir" "$repo_full_name" "$token"
            ((updated_repos++))    
        else
            echo "  ☑️ No change made to $repo_full_name"
            ((unchanged_repos++))
        fi
        cleanup_dir "$repo_dir"
        sleep 0.5
    done
    
    # Final report
    echo ""
    echo "🎯 Distribution Complete!"
    echo "✅ Updated repositories: $updated_repos/$total_repos"
    echo "☑️ Unchanged repositories: $unchanged_repos/$total_repos"
    echo "❌ Failed repositories: $failed_repos/$total_repos"
    
    if [[ $failed_repos -eq 0 ]]; then
        echo "🎉 All repositories processed successfully!"
    else
        echo "⚠️  Some repositories failed. Check the logs above."
    fi
}

# Delete dir
cleanup_dir() {
    local cleaned_dir=$1
    echo "🧹 Cleaning $cleaned_dir directory..."
    if [[ -d "$cleaned_dir" ]]; then
        rm -rf "$cleaned_dir"
    fi
}

cleanup_repos(){
    cleanup_dir $repos_dir
    echo "✅ Cleanup completed"
}

# Check dependencies
check_dependencies() {
    local deps=("curl" "jq" "base64" "openssl" "git")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error_exit "Missing required dependencies: ${missing_deps[*]}. Please install them."
    fi
}

# Signal handler for cleanup
cleanup_on_exit() {
    echo ""
    echo "🛑 Script interrupted. Cleaning up..."
    cleanup_repos
    exit 1
}

# Main execution
main() {
    echo "🚀 Git-Based Task Distribution Script Started"
    
    # Set up signal handlers for cleanup
    trap cleanup_on_exit INT TERM
    
    check_dependencies
    
    distribute_tasks
    
    cleanup_repos
    
    echo "✨ Script completed successfully!"
}

# Run main function
main "$@"
