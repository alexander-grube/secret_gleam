import dot_env
import dot_env/env
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/pgo

pub fn main() {
  io.println("Hello from secret_gleam!")

  dot_env.load()

  case env.get("TESTVAR") {
    Ok(value) -> io.println(value)
    Error(_) -> io.println("something went wrong")
  }

  let db_host = case env.get("DB_HOST") {
    Ok(value) -> value
    Error(_) -> "localhost"
  }

  let db_user = case env.get("DB_USER") {
    Ok(value) -> value
    Error(_) -> "root"
  }

  let db_pass = option.from_result(env.get("DB_PASS"))

  let db_name = case env.get("DB_NAME") {
    Ok(value) -> value
    Error(_) -> "my_database"
  }

  let db =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        user: db_user,
        password: db_pass,
        host: db_host,
        database: db_name,
        pool_size: 15,
      ),
    )

  let sql =
    "
  select
    message
  from
    secret_message
    "

  let assert Ok(response) =
    pgo.execute(sql, db, [], dynamic.element(0, dynamic.string))

  response.count
  |> int.to_string
  |> io.println

  response.rows
  |> list.map(fn(row) {
    row
    |> io.println
  })

  Nil
}
