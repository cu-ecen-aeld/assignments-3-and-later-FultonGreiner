#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

int main(int argc, char *argv[])
{
    char  *writefile = NULL;
    char  *writestr  = NULL;
    FILE  *fo        = NULL;
    size_t tx_bytes  = 0x0ULL;

    openlog("assignment-2", LOG_PID, LOG_USER);

    if ( 1 == argc )
    {
        syslog(LOG_ERR, "Missing writefile and writestr arguments!\n");
        exit(1);
    }
    else if ( 2 == argc )
    {
        syslog(LOG_ERR, "Missing writestr argument!\n");
        exit(1);
    }

    writefile = strndup(argv[1], strlen(argv[1]));
    writestr = strndup(argv[2], strlen(argv[2]));

    syslog(LOG_DEBUG, "Writing %s to %s\n", writestr, writefile);

    fo = fopen(writefile, "w");
    if ( NULL == fo )
    {
        syslog(LOG_ERR, "Failed to create file '%s'!\n", writefile);
        exit(1);
    }

    tx_bytes = fwrite(writestr , sizeof(char), strlen(writestr), fo);

    free(writefile);
    free(writestr);

    closelog();

    return 0;
}
