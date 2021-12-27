package odin_pgsql

import pg "libpq"

import "core:fmt"

My_Data :: struct {
  name: string,
  number: i32,
  small_num: i8,
  big_num: i64,
}

main :: proc() {
  connection := pg.PQconnectdb(
    "host=localhost connect_timeout=10 password=password user=postgres",
  )
  defer pg.PQfinish(connection)

  if pg.PQstatus(connection) != .OK {
    fmt.printf("connection error: %s\n", pg.PQerrorMessage(connection))
  } else {
    fmt.println("Connected to postgres")
  }

  data, ok := pg.query(connection, "select * from people", My_Data)
  if !ok {
    fmt.printf("pg.query error: %s\n", pg.PQerrorMessage(connection))
  } else {
    fmt.printf("%#v\n", data)
  }
}
