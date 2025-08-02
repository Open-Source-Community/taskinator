# Taskinator: Task Automation System

## Overview

**Taskinator** is a Bash-based automation system for managing, distributing, and grading tasks, developed by OSC Linux. It aims to streamline the delivery and grading of tasks, both internally and during events and workshops.
---

## General Workflow

1. **Repository Creation**  
   Each student runs `create_repo.sh` to create a private repository where they will recieve and solve their tasks.
   - Board members are added as collaborators.
   - Task-Handler GitHub app is installed to the repo.
   - The student submits the repo link in a form.


2. **Task Distribution**  
    
    - distribute.sh distributes task files from a central location to all student repositories.
    - Is currently triggered by commenting on an issue

3. **Task Grading**  
   - Running grade_task.sh to automatically grade student submissions and generate a results CSV.
   - Also uploads the result to the students' task repo
   - Is currently triggered by commenting on an issue

---

## Script Details

### 1. create_repo.sh

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
