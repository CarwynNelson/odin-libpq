#include "libpq-fe.h"
#include <stdlib.h>
#include <stdio.h>

int main()
{
  const char* connection_info = "dbname = postgres";
  PGconn* connection = PQconnectdb(connection_info);

  if (PQstatus(connection) != CONNECTION_OK) {
    fprintf(stderr, "%s", PQerrorMessage(connection));
    exit(1);
  }
}
