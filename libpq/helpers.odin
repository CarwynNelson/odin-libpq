package libpq

import "core:reflect"
import "core:strconv"
import "core:mem"

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
      } else if type == INT2OID || type == INT4OID || type == INT8OID {
        // NOTE If we were to be strict about it you would not allow
        // marshalling this value into an unsigned int as postgres stores these
        // as signed numbers, so they could be negative
        if field.type.id == u8 ||
          field.type.id == u16 ||
          field.type.id == u32 ||
          field.type.id == u64 {
          src, _ := strconv.parse_uint(string(value))
          mem.copy(field_ptr, &src, field.type.size)
        } else if field.type.id == i8 ||
          field.type.id == i16 ||
          field.type.id == i32 ||
          field.type.id == i64 {
          src, _ := strconv.parse_int(string(value))
          mem.copy(field_ptr, &src, field.type.size)
        } else {
          assert(false, "Trying to marshal non-integer type into integer")
        }
      } else if type == FLOAT4OID || type == FLOAT8OID {
        if field.type.id == f32 {
          src, _ := strconv.parse_f32(string(value))
          mem.copy(field_ptr, &src, field.type.size)
        } else if field.type.id == f64 {
          src, _ := strconv.parse_f64(string(value))
          mem.copy(field_ptr, &src, field.type.size)
        } else {
          assert(false, "Trying to marshal non-float type into float")
        }
      } else {
        // TODO handle this better. The user of this function
        // should be able to decide if this causes a crash at runtime
        assert(false, "Unsupported type")
      }
    }
    append(&data, item)
  }

  return data, true
}
