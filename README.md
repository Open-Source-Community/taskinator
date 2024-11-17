# Automation-System-Linux

Git Taskinator automates task delivery and validation of correctness.

# Task system

## Goals

- Automate task submission and grading process
- Verify using the command line
- Expose members to scripting and Git early on
- Showcase the power of scripting and CI/CO

## Required Files

- Google sheet with the following schema

| Name | Discord | Github Repo Link | Task 1 Status | Task 2 Status | ... |
| ---- | ------- | ---------------- | ------------- | ------------- | --- |

## Task status

- Correct
- Late (must also be correct)
- Incorrect
- Not Submitted

## Workflow

#### 1. Initializing

- Each member will run a script to:
  - Create a private repository.
  - Clone the repo locally
  - Add "osc" as a contributor.
- **Note**: Create google form to collect GitHub usernames/repo links
  - Current ideas to write this in the sheet automatically would expose the Google Sheet API secret.

#### 2. Publishing new task :

- For every new task, create task folder for session (responsibility of session leaders).
  - Create a folder locally named “Task_X.”
  - Add a `README.md` file to describe the task.
  - Include an empty `commands.sh` file for writing task commands.
  - Add any necessary files or folders.
  - Include an **encrypted/binary** `test.sh` script.
    - If task is wrong, print a descriptive error message and return -1.
    - If task is correct, print success and return 0.
  - Encrypt using the provided script.
- For each member:
  - Clone their repository.
  - Copy the task folder to their repository.
  - Push the changes.

#### 3. Submitting task:

1.  Run the 'test.sh' to check if task is correct
2.  If test fails, display a warning with the option to proceed submitting an incorrect task
3.  If test succeeds or user decided to proceed:
    - Add and commit changes.
    - Push to remote.

- **Note**: Using this script is optional. Members can add, commit and push their changes on their own.

#### 4. Grading tasks

- Take task number as argument T
- Pass --late option to mark correct tasks as "late"
- For every member in sheet whose task T status is either "incorrect" or "not submitted":
  - Clone tasks repo
  - Run 'test.sh'
  - Update task status in Google Sheet

## Scripts

1. **create_repository.sh**

   ```bash
   # Sample script
   gh auth login
   gh repo create Linux-25-Tasks --private --clone
   gh repo add-collaborator Linux-25-Tasks --username Open-Source-Community --permission admin

   ```

2. **add_new_task.sh**

3. **submit_task.sh**

4. **grade_tasks.sh**

5. **script_to_binary.sh** / **encrypt_script.sh**

## Design choices

- Using task upload as a chance to practice Git skills vs **aiming to minimize Git overhead during task submission.**

  - This would make the system more generic and perhaps more useful to other committess
  - Other ways to put Git skills to practice (Documentation project)

- Letting members create repos on their account vs creating task repos on OSC org
- Grading tasks upon submission (GitHub action, handling Google Sheets API token secret depending on previous point) vs **upon manually running grading script on all submissions**
  - A GitHub action could be set up, but unfortunaly would expose the Google Sheet API token. Making it a secret wouldn't help because the current approach relies on the member creating their repo, which makes them an admin by default.
