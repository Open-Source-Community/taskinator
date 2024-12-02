import csv
import sys
import os
from git import Repo, GitCommandError
import shutil

# Arguments given when running script
git_accounts_file = sys.argv[1]
task_folder = sys.argv[2]

# Task number
task_num = input("Enter task number: ")

# Reading CSV file
with open(git_accounts_file, 'r') as accounts:
    reader = csv.reader(accounts)
    git_data = list(reader)

# Check if the cloned repos directory exists
cloned_repos_path = "./Cloned Repos"
if not os.path.exists(cloned_repos_path):
    os.mkdir(cloned_repos_path)

# Clone or pull repositories
for repo_url in git_data:
    # Ensure repo_url is a string and not empty
    if not repo_url:
        continue
    
    # Extract a safe directory name from the repo URL
    repo_name = os.path.splitext(os.path.basename(repo_url[0]))[0]
    repo_path = os.path.join(cloned_repos_path, repo_name)
    
    try:
        # If repo doesn't exist, clone it
        if not os.path.exists(repo_path):
            Repo.clone_from(repo_url[0], repo_path)
            print(f"Cloned repository: {repo_url[0]}")
        else:
            # If repo exists, pull latest changes
            repo = Repo(repo_path)
            origin = repo.remotes.origin
            
            # Fetch first, then pull
            origin.fetch()
            origin.pull()
            print(f"Pulled latest changes for: {repo_url[0]}")
        
        # Stage, commit, and push changes
        repo = Repo(repo_path)
        
        # Copy the task folder to the repository
        task_dest_path = os.path.join(repo_path, task_folder)
        
        # Remove existing task folder if it exists
        if os.path.exists(task_dest_path):
            shutil.rmtree(task_dest_path)
        
        # Copy the entire task folder
        shutil.copytree(task_folder, task_dest_path)
        
        # Add the copied task folder
        repo.git.add(task_folder)
        
        # Commit and push
        repo.index.commit(f'Task number {task_num} added')
        origin = repo.remotes.origin
        origin.push()
        
        print(f"Committed and pushed task folder for: {repo_url[0]}")
    
    except GitCommandError as e:
        print(f"Git error processing repository {repo_url[0]}:")
        print(f"Error details: {e}")
        print(f"Error stdout: {e.stdout}")
        print(f"Error stderr: {e.stderr}")
    except Exception as e:
        print(f"Unexpected error processing repository {repo_url[0]}: {e}")