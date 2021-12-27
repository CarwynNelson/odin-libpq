package odin_pgsql

import "core:c"
import "core:fmt"
import "core:strconv"
import "core:reflect"
import "core:strings"
import "core:mem"
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

// From libpq-fe.h
Oid :: distinct c.uint
VARCHAROID :: 1043
INT4OID    :: 23

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

// would Result_Cursor be a better name?
// probably not?
Result_Metadata :: struct {
  column_count: i32,
  row_count: i32,
}
My_Data :: struct {
  name: string,
  number: u32,
}

pg_query :: proc(c: ^PGconn, query: cstring, $T: typeid) -> ([dynamic]T, bool) {
  data: [dynamic]T

  query_result := PQexec(c, query)
  defer PQclear(query_result)

  if status := PQresultStatus(query_result); status != .TUPLES_OK {
    // TODO: handle empty query specifically? maybe instead of returning
    // a bool we can return an enum? or maybe a bool and an enum?
    return nil, false
  }

  column_count := PQnfields(query_result)
  row_count    := PQntuples(query_result)

  for row in 0..row_count-1 {
    item: T
    for column in 0..column_count-1 {
      column_name := string(PQfname(query_result, column))

      field := reflect.struct_field_by_name(T, column_name)
      if field.type == nil {
        continue
      }

      field_ptr := rawptr(uintptr(&item) + field.offset)
      field_val := any{field_ptr, field.type.id}
      value := PQgetvalue(query_result, row, column)

      type := PQftype(query_result, column)
      if type == VARCHAROID {
        switch dst in &field_val {
          case string:
          dst = string(value)
          case cstring:
          dst = value
        }
      } else if type == INT4OID {
        switch field.type.id {
        case u32:
          src, _ := strconv.parse_uint(string(value))
          mem.copy(field_ptr, &src, field.type.size)
        }
      } else {
        // unsupported type at the moment
        // TODO handle this better. The user of this function
        // should be able to decide if this causes a crash at runtime
        assert(false)
      }
    }
    append(&data, item)
  }

  return data, true
}

main :: proc() {
  connection := PQconnectdb(
    "host=localhost connect_timeout=10 password=password user=postgres",
  )
  defer PQfinish(connection)

  if PQstatus(connection) != .OK {
    fmt.printf("connection error: %s\n", PQerrorMessage(connection))
  } else {
    fmt.println("Connected to postgres")
  }

  data, ok := pg_query(connection, "select * from people", My_Data)
  if !ok {
    fmt.printf("pg_query error: %s\n", PQerrorMessage(connection))
  } else {
    fmt.printf("%#v\n", data)
  }
}
