package libpq

import "core:reflect"
import "core:strconv"
import "core:mem"

// would Result_Cursor be a better name?
// probably not?
Result_Metadata :: struct {
  column_count: i32,
  row_count: i32,
}

query :: proc(
  c: ^PGconn,
  query: cstring,
  $T: typeid,
) -> ([dynamic]T, bool) {
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
