# Automation-System-Linux
Git Taskinator automate task delivery and validation of correctness.

# Task system

## Goals

- Automate task submission and grading process
- Verify using the command line
- Expose members to scripting and Git early on
- Showcase the power of scripting and CI/CO

## Workflow

1. **Initializing**  
   - Each member will run a script to:
	   - Create a private repository.
	   - Add "osc" as a contributor.
2. updating : 
	- it's managed by osc, Include
	2. adding new folder , files , testing files ..etc.
4. Pushing:
	- After user finishing tasks , it's time to push it 
	1. system will check if task is correct first
	2. second, it will take the generated key from the task and it add it to a new file 
	3. finally , it will push the task to the repository
4. After Pushing :
	- it will be a github action, that is taken when user pushing a task
	- it will run a script to notify admin 
		- notification may be a lot of things like : (sending user information to admin, adding user information at somewhere,...etc)


### Initializing

**Sample script** for creating user repository:

```bash
# Add messages explaining what the script will do
gh auth login
gh repo create Linux-25-Tasks --private --clone
gh repo add-collaborator Linux-25-Tasks --username Open-Source-Community --permission admin

```

**initialize.sh script:**
-> will do
1. creating user repository
2. notify admin that user created a repo 
	1. send email to admin, or adding user to a remote sheet


### Updating 
-> sending updates to user repo

**adding_new_task.sh**: by admin
1. cloning user repo
2. adding new task (task folder, new tests)
3. push it

**update.sh**: by user
1. user will run it to get new updates (get new tasks)

### Pushing
-> push user's task

**push_task.sh**: 
	1. Go to the task branch and folder, If the task is already marked as done in the tracking sheet, skip it.
	2. first will check if task is correct, if not it will be crash
	3. second, it will take the generated key from the test file of task then adding it to new file
	4. finally , it will push the task to the repository
	
## Limitations
- 