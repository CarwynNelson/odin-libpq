package odin_pgsql

import "core:c"
import "core:fmt"
import "core:strconv"
foreign import libpq "libpq.dylib"

@(default_calling_convention="c")
foreign libpq {
  PQconnectdb :: proc(conninfo: cstring) -> ^PGconn ---
  PQfinish :: proc(connection: ^PGconn) ---
  PQstatus :: proc(connection: ^PGconn) -> ConnStatusType ---
  PQerrorMessage :: proc(connection: ^PGconn) -> cstring ---
  PQexec :: proc(connection: ^PGconn, query: cstring) -> ^PGresult ---
  PQresultStatus :: proc(result: ^PGresult) -> ExecStatusType ---
  PQntuples :: proc(result: ^PGresult) -> c.int ---
  PQnfields :: proc(result: ^PGresult) -> c.int ---
  PQfnumber :: proc(result: ^PGresult, field_name: cstring) -> c.int ---
  PQfname   :: proc(result: ^PGresult, field_num: c.int) -> cstring ---
  PQgetvalue :: proc(
    result: ^PGresult,
    row_num: c.int,
    column_num: c.int,
  ) -> cstring ---
}

PGconn :: struct {}
PGresult :: struct {}
ConnStatusType :: enum c.int {
	OK,
	BAD,
	/* Non-blocking mode only below here */

	/*
	 * The existence of these should never be relied upon - they should only
	 * be used for user feedback or similar purposes.
	 */
	STARTED,			      /* Waiting for connection to be made.  */
	MADE,			          /* Connection OK; waiting to send.     */
	AWAITING_RESPONSE,	/* Waiting for a response from the postmaster. */
	AUTH_OK,			      /* Received authentication; waiting for backend startup. */
	SETENV,			        /* This state is no longer used. */
	SSL_STARTUP,		    /* Negotiating SSL. */
	NEEDED,			        /* Internal state: connect() needed */
	CHECK_WRITABLE,	    /* Checking if session is read-write. */
	CONSUME,			      /* Consuming any extra messages. */
	GSS_STARTUP,		    /* Negotiating GSSAPI. */
	CHECK_TARGET,	      /* Checking target server properties. */
	CHECK_STANDBY,	    /* Checking if server is in standby mode. */
}

ExecStatusType :: enum c.int {
	EMPTY_QUERY = 0,		/* empty query string was executed */
	COMMAND_OK,			/* a query command that doesn't return
								 * anything was executed properly by the
								 * backend */
	TUPLES_OK,			/* a query command that returns tuples was
								 * executed properly by the backend, PGresult
								 * contains the result tuples */
	COPY_OUT,				/* Copy Out data transfer in progress */
	COPY_IN,				/* Copy In data transfer in progress */
	BAD_RESPONSE,			/* an unexpected response was recv'd from the
								 * backend */
	NONFATAL_ERROR,		/* notice or warning message */
	FATAL_ERROR,			/* query failed */
	COPY_BOTH,			/* Copy In/Out data transfer in progress */
	SINGLE_TUPLE,			/* single tuple from larger resultset */
	PIPELINE_SYNC,		/* pipeline synchronization point */
	PIPELINE_ABORTED,		/* Command didn't run because of an abort
								 * earlier in a pipeline */

}

main :: proc() {
  connection := PQconnectdb("host=localhost connect_timeout=10 password=password user=postgres")
  defer PQfinish(connection)

  if PQstatus(connection) != .OK {
    fmt.printf("%s", PQerrorMessage(connection))
  } else {
    fmt.println("Connected to postgres")
  }

  result := PQexec(connection, "select * from people")
  if PQresultStatus(result) != .TUPLES_OK {
    fmt.printf("SET failed: %s", PQerrorMessage(connection))
    /* PQclear(result) */ // is this needed?
    return;
  }

  Result_Metadata :: struct {
    column_count: i32,
    row_count: i32,
  }
  My_Data :: struct {
    number: u32,
    name: string,
  }

  result_meta: Result_Metadata
  datas: [dynamic]My_Data

  result_meta.column_count = PQnfields(result);
  result_meta.row_count  = PQntuples(result);
  fmt.printf("Result: %#v\n", result_meta)

  // lazy implementation for now, could improve by not
  // using a dynamic array since I know the size of things
  // ahead of time.
  for row:i32=0;row<=result_meta.row_count-1;row+=1 {
    data: My_Data
    for column:i32=0;column<=result_meta.column_count-1;column+=1 {
      // get the column name
      column_name := PQfname(result, column)
      value := string(PQgetvalue(result, row, column))
      if column_name == "name" {
        data.name = value
      }
      if column_name == "number" {
        value, _ := strconv.parse_uint(value)
        data.number = u32(value)
      }
    }
    append(&datas, data) // move this down to the end?
  }

  fmt.printf("%v\n", datas)
}
