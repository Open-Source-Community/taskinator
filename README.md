# Taskinator: Task Automation System

## Overview

**Taskinator** is a Bash-based automation system for managing, distributing, and grading tasks, developed by OSC Linux. It aims to streamline the delivery and grading of technical tasks.

---

## What's The Issue?

OSC hosts a lot of events throughout the year (workshops, training, etc) where we assign tasks. We also assign tasks to our members throuhgout the season. All of these tasks need to be published, graded and receive feedback. 

Automating this process frees supporters for other roles, like supporting students and preparing the material and presenation. It also allows us to increase the capacity of people we can train, since task-grading is no longer a bottleneck.

-- 

## How does this work?

The system is language and technology-agnostic, but has one constraint: The tasks need to be **testable**, meaning that a script can be written to grade them.
   
Your task as an instructor is:
- Guiding the students through their task repository setup
- Creating the tasks and their test scripts
- Triggering task publishing and grading (can be automated entirely, but we chose to keep it manual)

Everything else the system handles for you.
 
---

# Setup
## 1. Task Handler GitHub App
- Create a GitHub app. This will be the link between your central repo and student repos.

## 2. Central Repo Setup
- Create a private GitHub repository to serve as the center for task distribution and grading. We'll call it the **central repo**.
- Copy the distribution and grading scripts, along with the GitHub actions, to your central repo. It should look like this:

```
central-repo
├── .github/
├── distribute.sh
└── grade_task.sh
```
- Create the following GitHub issues
**in order** in your central repo:
   1. Trigger Grade Tasks
   2.  Trigger Distribute Tasks
- You can use the GitHub website or CLI.
   ```bash
   gh issue create -t "Trigger Grade Tasks" -b ""
   gh issue create -t "Trigger Distribute Tasks" -b ""
   ```
- The grading issue should be #1, and the distribution issue #2.


## 2. Student Repo Setup
- Each student should create a private task repo using `create_reps.sh`
   - **Note**: Make sure to edit it first with the link to your task handler app and the collaborators you want to add.
   - For reference, [here are the instructions](https://gist.github.com/thisisamna/f677bf7fc531dc62bda8fa8ee00a0a9f) we provided to our trainees.
- In addition to creating the repo, the script does two main things:
     - Instructors/supervisers are added as collaborators.
     - Task handler app is installed to the repo.
- The student should then submit the repo link in a form along with their name, student ID< and any relevant information.
   - This will not be needed by the system; it will identify students by their GitHub accounts only.

## 3. Task Creation
- Create a folder for each task in this format:

   ```
   central-repo
   └── Task-1
      ├── README.md
      ├── task_1_test.sh
      └── submit.sh
   ```
   - `Task-X` and `task_X_test.sh` are required to be in this exact format. 
   - `submit.sh` should be copied from this repo into each task folder.
- Commit and push the task to the central repo.

```bash
git add Task-1/
git commit -m "Added task 1"
git push
```
## 3. Task Distribution
- To push **all uploaded tasks** to every student repo, comment on the "Trigger Task Distribution" issue. 
- The comment body doesn't matter.
- **Design choice:** 
   - The system excludes test scripts in the format `task-x-test.sh`. This is to allow for CTF-like tasks that ask to find a key, etc, where publishing the script would give away the solution.
   - It can be beneficial to provide the test script. In this case, you can copy it under a different name, or modify the system to remove this exclusion.
- Each student will need to
   - Pull the changes into their task repo.
   - Solve the task.
   - Commit and push their changes.

## 4. Task Grading
- To trigger task grading, comment on the "Trigger Task Grading" issue. 
   - **To grade a single task:** Comment the task number only, eg: "1"
   - **To grade all tasks:** Comment anything that is not a number
- This will produce a CSV file in the task folder with the results.
- It will also publish each student's results to their task repo, in the form of a markdown file in the task folder.
   - They will need to run `git pull` to see the results. 

---

#  Tailoring the System to Your Needs


 
-  --
   
#  # Script Details
 - 
#  ## 1. create_repo.sh
   
**Modifiable Variables:** 

- **REPO_NAME**: Name of the repository to create 
- **COLLABORATORS**: Array of GitHub usernames to add as collaborators

**Outputs:**
- Creates a private repository under the authenticated user's account.
- Adds each collaborator with admin rights.
- Installs the GH app

Students will run

```bash
./create_repo.sh
```

---

### 2. distribute.sh

**Purpose:**  
Distributes task files to all student repositories using the GitHub App API.

**Inputs:**
- **APP_ID** and **APP_PRIVATE_KEY**: GitHub App credentials (set as environment variables).
- **TASKS_DIR**: Directory containing task files (default: current directory).
- **Task file pattern**: Only files matching "Task" in their name are distributed.

**Outputs:**
- Copies/updates task files in each student repository.

```bash
export APP_ID=your_app_id
export APP_PRIVATE_KEY="your_private_key"
./distribute.sh
```

---

### 3. grade_task.sh

**Purpose:**  
Clones each student repository, runs a test script, and records the result in a CSV file.

**Inputs:**
- **source_file**: CSV file with student info and repo links (modifiable variable).
- **test_script**: Path to the grading/test script (modifiable variable).
- **task_number**: Task/session number (passed as argument).

**Outputs:**
- **target_file**: CSV file with grading results.
- **Result.md**: Markdown file with grading summary pushed to student repo.

```bash
./grade_task.sh 1
```
*(where `1` is the task/session number)*

---

## Environment & Dependencies

- **GitHub CLI (`gh`)**: Required for create_repo.sh.
- **GitHub App**: Required for distribute.sh (set `APP_ID` and `APP_PRIVATE_KEY`).
- **Dependencies for distribute.sh**: `curl`, `jq`, `base64`, `openssl`.
- **Bash**: All scripts are Bash scripts and should be run in a Unix-like environment.

---


## References
- Badr's testing script
    - [Video](https://youtu.be/Qu_9GhIeADE?si=3tGtLL8Qmk8RqYQL)
    - [Script](https://github.com/Badr-1/scripts/tree/main/testing)
