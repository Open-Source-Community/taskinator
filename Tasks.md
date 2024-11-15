1. For every task:

   - Create a folder locally named “Task_XYZ.”
   - Add a `README.md` file to describe the task.
   - Include an empty `commands.sh` file for writing task commands.
   - Add any necessary files or folders.
   - Include an **encrypted** `test.sh` script.

2. When the task is correct:

   - Running `test.sh` will generate a password based on a fixed task password and their GitHub/email.
   - The password will be written to a `password` file.

3. For each member:

   - Clone their repository.
   - Create a branch for the task.
   - Copy the task folder to their repository.
   - Push the changes.

4. On a push to a task branch:

   - Go to the task branch and folder
   - If the task is already marked as done in the tracking sheet, skip it.
   - Run the corresponding check script.

5. Check script process:

   - Copy their `password` file to `password_submitted`.
   - Run `commands.sh` and then `test.sh` to validate their approach (this will overwrite the `password` file).
   - Regenerate the password using the fixed task password and their GitHub/email (computed directly).
   - Compare the regenerated password to the one in `password_submitted.`

6. Results:

   - If the passwords match:
     - Mark the task as done in the sheet
     - Create a `result.txt` file with “Congrats! Your task has been accepted”.
   - If the passwords don’t match:
     - Mark the task as rejected in the sheet
     - Create a `result.txt` file explaining that the script must be run on their own machine with correct Git credentials set up.

7. Final steps:
   - Restore the original `password` file and delete `password_submitted`.
   - Commit the updates and push them to their repository.
