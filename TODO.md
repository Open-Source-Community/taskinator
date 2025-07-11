# Data Repo : private (contain evaluations of tasks)

1. sheet : names, user name (from forms )
2. Task Folder:
	1. Task sheet: Repo, result(correct, wrong, not submitted), user Name (from script) (.csv)
	2. plugin script of task()

action -> run (grading) script: -> plugin script of task() -> grading script pushing result in student Repo

# Central Repo (Linux-Tasks) : public
1. all tasks folder
2. distribute script
3. action to distribute tasks
4. file contain the names of unchanged files

TODO:
1. apply (File with file names to be excluded from update (solution.sh, solution.txt etc))
2. add function (push data (repo, username)) -> Data Repo in task folder name
3. Install dependencies if not found

# Student Repo : Private
1. all tasks & solution

----
- Taskinator
    - Github action triggered upon new repo creation
        - File with file names to be excluded from update (solution.sh, solution.txt etc)
        - Install dependencies if not found
        - Create templates for task readme and solution file
        - How to trigger test script?



