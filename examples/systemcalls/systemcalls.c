#include "systemcalls.h"

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// #include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{

/*
 * TODO  add your code here
 *  Call the system() function with the command set in the cmd
 *   and return a boolean true if the system() call completed with success
 *   or false() if it returned a failure
*/
    int status = 0x0;

    status = system(cmd);
    if ( 0 != status )
    {
        printf("Error: system() returned status %d for command '%s'!\n", status, cmd);
        return false;
    }

    return true;
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{
    bool retval = false;
    char *command[count + 1];
    int child_status;
    pid_t child_pid;
    va_list args;

    va_start(args, count);

    for(int i = 0; i < count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    // command[count] = command[count];

/*
 * TODO:
 *   Execute a system command by calling fork, execv(),
 *   and wait instead of system (see LSP page 161).
 *   Use the command[0] as the full path to the command to execute
 *   (first argument to execv), and use the remaining arguments
 *   as second argument to the execv() command.
 *
*/

    fflush(stdout);

    child_pid = fork();
    if (child_pid < 0)
    {
        perror("fork");
        return false;
    }
    else if (child_pid == 0)
    {
        execv(command[0], command);
        perror("execv");
        _exit(EXIT_FAILURE);
    }
    else
    {
        if (waitpid(child_pid, &child_status, 0) == -1)
        {
            perror("waitpid");
            return false;
        }

        if (WIFEXITED(child_status))
        {
            int exit_status = WEXITSTATUS(child_status);
            if (exit_status == 0)
            {
                printf("Child process executed successfully.\n");
                retval = true;
            }
            else
            {
                printf("Child process exited with status %d!\n", exit_status);
                retval = false;
            }
        }
        else
        {
            printf("Child process did not exit successfully!\n");
            retval = false;
        }
    }

    va_end(args);

    return retval;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    bool retval = false;
    char * command[count + 1];
    int child_status;
    int fd = 0x0;
    pid_t child_pid;
    va_list args;

    va_start(args, count);
    for (int i = 0; i < count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    // command[count] = command[count];


/*
 * TODO
 *   Call execv, but first using https://stackoverflow.com/a/13784315/1446624 as a refernce,
 *   redirect standard out to a file specified by outputfile.
 *   The rest of the behaviour is same as do_exec()
 *
*/

    fd = open(outputfile, O_WRONLY|O_TRUNC|O_CREAT, 0644);
    if ( 0 > fd )
    {
        printf("Failed to open file: '%s'!\n", outputfile);
        return false;
    }

    fflush(stdout);

    child_pid = fork();
    if (child_pid < 0)
    {
        perror("fork");
        close(fd);
        return false;
    }
    else if (child_pid == 0)
    {
        // Child process
        if (dup2(fd, STDOUT_FILENO) < 0)
        {
            perror("dup2");
            close(fd);
            _exit(EXIT_FAILURE);
        }
        close(fd);

        execv(command[0], command);
        perror("execv");
        _exit(EXIT_FAILURE);
    }
    else
    {
        // Parent process
        close(fd);

        if (waitpid(child_pid, &child_status, 0) == -1)
        {
            perror("waitpid");
            return false;
        }

        if (WIFEXITED(child_status))
        {
            int exit_status = WEXITSTATUS(child_status);
            if (exit_status == 0)
            {
                printf("Child process executed successfully.\n");
                retval = true;
            }
            else
            {
                printf("Child process exited with status %d!\n", exit_status);
                retval = false;
            }
        }
        else
        {
            printf("Child process did not exit successfully!\n");
            retval = false;
        }
    }
    
    va_end(args);

    return retval;
}
