package libpq

import "core:c"

foreign import libpq "libpq.dylib"

// From libpq-fe.h
@(default_calling_convention="c")
foreign libpq {
  PQconnectdb :: proc(conninfo: cstring) -> ^PGconn ---
  PQfinish :: proc(connection: ^PGconn) ---
  PQstatus :: proc(connection: ^PGconn) -> Connection_Status ---
  PQerrorMessage :: proc(connection: ^PGconn) -> cstring ---
  PQexec :: proc(connection: ^PGconn, query: cstring) -> ^PGresult ---
  PQclear :: proc(result: ^PGresult) ---
  PQresultStatus :: proc(result: ^PGresult) -> Exec_Status ---
  PQntuples :: proc(result: ^PGresult) -> c.int ---
  PQnfields :: proc(result: ^PGresult) -> c.int ---
  PQfnumber :: proc(result: ^PGresult, field_name: cstring) -> c.int ---
  PQfname   :: proc(result: ^PGresult, field_num: c.int) -> cstring ---
  PQgetvalue :: proc(
    result: ^PGresult,
    row_num: c.int,
    column_num: c.int,
  ) -> cstring ---
  PQftype :: proc(result: ^PGresult, field_num: c.int) -> Oid ---
}

// The implementation of these is private
// so they are effectively handles
PGconn :: struct {}
PGresult :: struct {}

Oid :: distinct c.uint
Connection_Status :: enum c.int {
  OK,
  BAD,
  STARTED,
  MADE,
  AWAITING_RESPONSE,
  AUTH_OK,
  SETENV,
  SSL_STARTUP,
  NEEDED,
  CHECK_WRITABLE,
  CONSUME,
  GSS_STARTUP,
  CHECK_TARGET,
  CHECK_STANDBY,
}
Exec_Status :: enum c.int {
  EMPTY_QUERY = 0,
  COMMAND_OK,
  TUPLES_OK,
  COPY_OUT,
  COPY_IN,
  BAD_RESPONSE,
  NONFATAL_ERROR,
  FATAL_ERROR,
  COPY_BOTH,
  SINGLE_TUPLE,
  PIPELINE_SYNC,
  PIPELINE_ABORTED,
}

// From catalog/pg_type_d.h which can be viewed at
// src/backend/catalog/pg_type_d.h in the postgres source
VARCHAROID :: 1043
INT4OID    :: 23

