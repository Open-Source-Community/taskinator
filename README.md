# Taskinator: Automated Task Distribution and Grading System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)

**Taskinator** is a Bash-based automation system for distributing and grading programming assignments at scale. Built for OSC Ain Shams University's Linux Committee, it automates the entire task lifecycle from distribution to grading, enabling instructors to focus on teaching rather than logistics.

## Table of Contents

- [Background](#background)
- [Workflow](#workflow)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Usage Guide](#usage-guide)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contribution](#contribution)
- [Credits](#credits)
- [License](#license)

## Background

OSC hosts a lot of events throughout the year (workshops, training, etc) where we assign programming assignments. The traditional manual grading workflow created several bottlenecks:

- **Scalability**: Manual grading limited cohort sizes.
- **Resource allocation**: Instructors spent time grading instead of teaching or content creation.
- **Consistency**: Manual grading introduced subjectivity and human error.

The Linux committee decided to solve this the way we solve any problem we face ― you guessed it, by automating it!

Taskinator automates the entire task lifecycle through a distributed system architecture:

```
┌─────────────────┐
│  Central Repo   │  ← Instructors manage tasks here
│  (Private)      │
└────────┬────────┘
         │
         │ GitHub Actions + GitHub App
         │
    ┌────▼────┐
    │ Trigger │ (Issue comments)
    └────┬────┘
         │
    ┌────▼──────────────────────────┐
    │ Automated Distribution/Grading│
    └────┬──────────────────────────┘
         │
    ┌────▼────┬────▼────┬────▼────┐
    │Student 1│Student 2│Student N│
    │  Repo   │  Repo   │  Repo   │
    └─────────┴─────────┴─────────┘
```

## Workflow

1. Instructors create tasks with test scripts in central repo
2. Instructors comment on GitHub issue to trigger task distribution
3. Tasks are pushed to all student repos via GitHub App
4. Students solve and push solutions
5. Instructors comment on issue to trigger automated grading
6. Results published to each student's repo + aggregated summary

## Prerequisites

- A Linux-like environment with Bash
- Git
- GitHub CLI (`gh`) - [Installation guide](https://cli.github.com/)
- Sufficient GitHub Actions minutes
  - The free-tier was sufficient for our 3-week training for roughly 70 trainees, with 5 tasks to distribute and grade (and regrade a dozen times!)

## Quick Start

```bash
# 1. Clone this repository
git clone https://github.com/Open-Source-Community/taskinator

# 2. Create GitHub App (see Detailed Setup)
# Note your APP_ID and APP_PRIVATE_KEY

# 3. Set up central repository
gh repo create <central-task-repo> --private
cp -r <path-to-taskinator>/.github <central-task-repo>
cp <path-to-taskinator>/{distribute.sh,grade_task.sh} <central-task-repo>

# 4. Configure GitHub secrets
gh secret set APP_ID
gh secret set APP_PRIVATE_KEY

# 5. Create trigger issues
gh issue create -t "Trigger Grade Tasks" -b ""
gh issue create -t "Trigger Distribute Tasks" -b ""

# 6. Create your first task (example)
cd <central-task-repo>
mkdir Task-1
cd Task-1
cat > README.md << 'EOF'
# Task 1: Hello World
Write a bash script that prints "Hello, World!"
EOF

cat > task_1_test.sh << 'EOF'
#!/bin/bash
output=$(bash solution.sh)
if [ "$output" = "Hello, World!" ]; then
    echo "PASS"
    exit 0
else
    echo "FAIL: Expected 'Hello, World!', got '$output'"
    exit 1
fi
EOF

chmod +x task_1_test.sh

# Copy submit script
cp <path-to-taskinator>/submit.sh .

# 7. Commit and push task
git commit -am "Add Task 1" && git push

# 8. Trigger task distribution
gh issue comment 2 --body "distribute"
```

## Detailed Setup

### Step 1: Create GitHub App

The GitHub App authenticates your central repo with student repositories.

1. Navigate to **GitHub Settings → Developer settings → GitHub Apps → New GitHub App**

2. Configure the app:

   - **Name**: `task-handler` (or your preferred name)
   - **Homepage URL**: Your organization website
   - **Webhook**: Disable (not needed)
   - **Repository permissions**:
     - Contents: Read & Write
     - Metadata: Read-only
   - **Where can this GitHub App be installed?**: Any account

3. Generate private key:

   - After creation, click "Generate a private key"
   - Save the downloaded `.pem` file securely
   - Note your **App ID** from the app settings page

### Step 2: Central Repository Setup

```bash
# Create and initialize central repo
gh repo create <central-task-repo> --private --clone
cd <central-task-repo>

# Copy system files
cp -r <path-to-taskinator>/.github/ .
cp <path-to-taskinator>/distribute.sh .
cp <path-to-taskinator>/grade_task.sh .

# Add GitHub secrets
gh secret set APP_ID --body "<your-app-id>"
gh secret set APP_PRIVATE_KEY < /path/to/private-key.pem

# Create trigger issues IN ORDER
gh issue create -t "Trigger Grade Tasks" -b ""      # This becomes issue #1
gh issue create -t "Trigger Distribute Tasks" -b "" # This becomes issue #2

# Verify issue numbers
gh issue list
```

⚠️ **Important**: Issue #1 must be grading, issue #2 must be distribution. The system relies on these numbers.

Finally, install the app to your central repo

- Go to your GitHub app settings page.
- Click 'Install App'.
- Grant access to "Only select repositories" and choose your central repo.

### Step 3: Student Repository Setup

Each student creates their own private task repository using the provided script.

**Instructor preparation**:

1. Edit `create_repo.sh` with your specific values:

   ```bash
   repo_name="osc-linux-tasks"
   collaborators=("instructor1" "instructor2" "ta1")
   task_handler_app="https://github.com/apps/your-taskinator-app"
   ```

2. Provide students with:
   - The `create_repo.sh` script
   - Instructions (see example below)

**Student workflow**:

```bash
# Authenticate GitHub CLI
gh auth login

# Verify authentication
gh auth status

# Run the repository creation script
bash create_repo.sh

# The script will:
# 1. Create a private repo named "osc-linux-tasks"
# 2. Add instructors as collaborators
# 3. Prompt to install the Task Handler app
```

**Example student instructions**: [View template](https://gist.github.com/thisisamna/f677bf7fc531dc62bda8fa8ee00a0a9f)

### Step 4: Task Creation

_Refer to this [template](/template/) for the task description and test script._

Tasks follow a standardized structure for automation:

```
central-repo/
├── Task-1/
│   ├── README.md           # Task description and requirements
│   ├── task_1_test.sh      # Grading script (required naming)
│   └── submit.sh           # Submission helper (copied from taskinator repo)
├── Task-2/
│   ├── README.md
│   ├── task_2_test.sh
│   └── submit.sh
```

- Folder: `Task-N` (where N is task number)
- Test script: `task_N_test.sh`
- These exact formats are required for the system to recognize tasks

The **test script** must follow the following guidelines:

- It should verify whether the solution is correct or not, either by running it or looking for expected artifacts that verify correctness (generated files, etc).
- It should exit with one of three status codes:

|     Status      | Exit Code | Description                                                                                              |
| :-------------: | :-------: | -------------------------------------------------------------------------------------------------------- |
|   CORRECT ✅    |     0     | The solution is correct.                                                                                 |
|  INCORRECT ❌   |     1     | The solution is incorrect or incomplete.                                                                 |
| NOTSUBMITTED ⚠️ |     2     | The solution is missing, or an error occurred while grading (e.g., not following submission guidelines). |

## Usage Guide

### Distributing Tasks

To distribute **all** tasks to **all** student repos:

```bash
# Via GitHub CLI
gh issue comment 2 --body "anything"

# Via web interface
# Go to issue #2 and add any comment
```

What happens:

1. GitHub Action triggers on comment
2. System identifies all folders matching `Task-*` pattern
3. For each student repo:
   - Clones repo
   - Copies task folders (excluding test scripts and results)
   - Commits and pushes changes

### Solving Tasks
1. Students pull incoming changes to receive the published tasks.

   ```bash
   cd <student-task-repo>
   git pull
   # New task folders appear
   ```
3. Students solve the task, and then submit.
   - Either by manually adding, committing and pushing using Git.
   - Or by using the provided helper `submit.sh` script in the [template folder](/template/submit.sh).


### Grading Tasks

To grade a specific task, comment on the "Trigger Grade Tasks" issue with the number of the task you want to grade.

```bash
gh issue comment 1 --body "2"  # Grades only Task-2
```

To grade all tasks, comment anything that is not just a number.

```bash
gh issue comment 1 --body "grade all"  # Any non-number triggers full grade
```

What happens:

1. GitHub Action triggers on comment
2. System clones all student repos
3. For each repo:
   - Runs corresponding test script(s)
   - Captures output and exit code
   - Generates markdown feedback
4. Publishes results:
   - Individual feedback to each student's repo
   - Aggregated CSV in central repo's task folder

### Viewing Results

Students can find their results in their task repo.

```bash
cd <student-task-repo>
git pull
cat Task-2/results.md
# Or view them from the GitHub webpage
```

Instructor can find aggregated results in the central repo.

```bash
cd central-repo/Task-2
cat results.csv
# Or view them from the GitHub webpage
```

## Customization

### Environment Variables

Set these as GitHub Secrets in your central repository:

```bash
APP_ID="123456"                    # Your GitHub App ID
APP_PRIVATE_KEY="-----BEGIN..."   # Your GitHub App private key
```

For local testing:

```bash
export APP_ID="123456"
export APP_PRIVATE_KEY="$(cat private-key.pem)"
```

### Hard-Coded Variables

These arguments to the system are set as hard-coded variables in the scripts. Modify as per your usage.

1. Repo Creation Script (`create_repo.sh`)

   - `repo_name`: Name of the repository to create
   - `collaborators`: Array of GitHub usernames to add as collaborators
   - `task_handler_app`: Link to your task handler GitHub app.

2. Task Distribution Script (`distribute.sh`)

   - `test_pattern`: Pattern of test scripts, to exclude them from distribution and to execute them when grading.
   - `result_pattern`: Pattern of grading result files, to exclude them from distribution.
   - `solution_pattern`: Pattern of solution files, to avoid overwriting them during task distribution.

3. Task Grading Script (`grade_task.sh`)
   - `results_summary`: Name of the CSV file containing results of all trainees for a given task (saved to the corresponding task folder in the central repo )
   - `result_file`: Name of the result file published to the trainees (saved in the corresponding task folder in the trainee's task repo)

## Troubleshooting

### Common Issues

**Issue**: Tasks not distributing to student repos

```bash
# Check GitHub Action logs
gh run list --workflow=distribute.yml
gh run view <run-id> --log

# Common causes:
# - GitHub App not installed on student repo
# - Naming convention violated (not Task-N/)
```

**Issue**: Grading fails or hangs

```bash
# Test script locally first
cd Task-1
bash task_1_test.sh  # Should exit 0 for pass

# Check for:
# - Infinite loops in test script
# - Missing permissions (chmod +x)
# - Buggy solutions (running commands like sleep, exit, etc)
```

**Issue**: Students not receiving results

```bash
# Check student repo from the website
# Student must run git pull to see results
```

### Getting Help

- Check GitHub action logs.
- Report bugs and request features through issues.
- Contact maintainers for support.

## Design Decisions

**Why issue comments as triggers?**

Since we were testing the system at scale for the first time, we wanted some level of oversight and control over it. However, it can be entirely automated using a different trigger for the actions, or using cron jobs.

**Why exclude test scripts from distribution?**

Some of the tasks we designed made this necessary. For example, we had a task where trainees needed to find a certain password within a large text file. Sharing the script would give away the solution.

However, we realize that the benefits of sharing the test script might outweigh this restriction. In this case, you can copy it under a different name, or modify the system to remove this exclusion.

**Why private student repos?**

To prevent sharing solutions between students, and to protect student solutions and grades.

**Why private central repo?**

Because it contains the test scripts, as well as summaries of grading results. This is info you presumably wouldn't want to be public.

## Future Enhancements

Potential improvements for contributors:

- [ ] Sanitizing solution scripts more robustly before running them
- [ ] Scheduled automatic grading
- [ ] Partial credit scoring
- [ ] Deadline enforcement and support for late submissions

## Contribution

Contributions are welcome! While we may not review PRs immediately, we encourage:

1. **Open an issue** describing your proposed feature/fix
2. **Fork the repository**
3. **Create a feature branch**: `git checkout -b feature/amazing-feature`
4. **Commit changes**: `git commit -m 'Add amazing feature'`
5. **Push to branch**: `git push origin feature/amazing-feature`
6. **Open a Pull Request**

Please ensure:

- Code follows existing style conventions
- Documentation is updated for new features

## Credits

This project was made with love by OSC Linux '25 committee, and was led by [Amna Ahmed](https://github.com/thisisamna) and [Hadeer Ramadan](https://github.com/hadeer-r).

Special thanks to [Badr Mohamed](https://github.com/Badr-1) for his invaluable feedback throughout this project, and for planting [this seed](https://github.com/Badr-1/scripts/tree/main/testing) that inspired it ([video demo](https://youtu.be/Qu_9GhIeADE?si=3tGtLL8Qmk8RqYQL)).

## License

MIT License - Feel free to use, modify, and build upon this project.

```
Copyright (c) 2025 Open Source Community, Ain Shams University

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

**Star this repo if you find it useful!** ⭐

For questions or support, open an issue or contact the maintainers or OSC Linux committee.
