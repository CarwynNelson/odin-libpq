package odin_pgsql

import "core:c"
import "core:fmt"
import "core:strconv"
foreign import libpq "libpq.dylib"

// From libpq-fe.h
@(default_calling_convention="c")
foreign libpq {
  PQconnectdb :: proc(conninfo: cstring) -> ^PGconn ---
  PQfinish :: proc(connection: ^PGconn) ---
  PQstatus :: proc(connection: ^PGconn) -> Connection_Status ---
  PQerrorMessage :: proc(connection: ^PGconn) -> cstring ---
  PQexec :: proc(connection: ^PGconn, query: cstring) -> ^PGresult ---
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
}

// From libpq-fe.h
PGconn :: struct {}
PGresult :: struct {}
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

main :: proc() {
  connection := PQconnectdb(
    "host=localhost connect_timeout=10 password=password user=postgres",
  )
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
