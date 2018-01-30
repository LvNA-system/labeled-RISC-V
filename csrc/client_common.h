// handle debug bus request
void handle_debug_request(const char *command, const char *reg, char *values);

// ********************* connection and initialization functions ******************************
void connect_server(const char *ip_addr, int port);

void disconnect_server(void);

void init_dtm(void);

/* We use the ``readline'' library to provide more flexibility to read from stdin. */
char *rl_gets(void);
