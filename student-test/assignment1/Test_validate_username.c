#include "unity.h"
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include "../../examples/autotest-validate/autotest-validate.h"
#include "../../assignment-autotest/test/assignment1/username-from-conf-file.h"

/**
* This function should:
*   1) Call the my_username() function in autotest-validate.c to get your hard coded username.
*   2) Obtain the value returned from function malloc_username_from_conf_file() in username-from-conf-file.h within
*       the assignment autotest submodule at assignment-autotest/test/assignment1/
*   3) Use unity assertion TEST_ASSERT_EQUAL_STRING_MESSAGE to verify the two strings are equal.  See
*       the [unity assertion reference](https://github.com/ThrowTheSwitch/Unity/blob/master/docs/UnityAssertionsReference.md)
*/
void test_validate_my_username()
{
    char *username_conf       = NULL;
    char *username_hard_coded = NULL;

    /* 1. Get hard-coded username */
    username_hard_coded = (char*)my_username(); /* typecast to avoid warning for 'const' */

    /* 2. Read configured username */
    username_conf = malloc_username_from_conf_file();

    /* 3. Assert equal */
    TEST_ASSERT_EQUAL_STRING_MESSAGE(username_hard_coded, username_conf, "Hard-coded username does not match configured username!\n");

    /* cleanup resources */
    free(username_hard_coded);
    free(username_conf);
}
