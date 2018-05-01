#include <stdlib.h>
#include <readline/readline.h>
#include <readline/history.h>

/* We use the ``readline'' library to provide more flexibility to read from stdin. */
char* rl_gets(void) {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("> ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}
