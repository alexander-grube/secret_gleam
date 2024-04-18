import dot_env
import dot_env/env
import gleam/bytes_builder
import gleam/dynamic
import gleam/http/elli
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/io
import gleam/json.{object, string}
import gleam/list
import gleam/option
import gleam/pgo

pub type Message {
  Message(message: String)
}

pub fn message_to_json(message: Message) -> String {
  object([#("message", string(message.message))])
  |> json.to_string
}

pub fn main() {
  io.println("Hello from secret_gleam!")

  dot_env.load()

  case env.get("TESTVAR") {
    Ok(value) -> io.println(value)
    Error(_) -> io.println("something went wrong")
  }

  let port = case env.get("PORT") {
    Ok(value) -> {
      case int.base_parse(value, 10) {
        Ok(value) -> value
        Error(_) -> 3000
      }
    }
    Error(_) -> 3000
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
  |> io.debug

  response.rows
  |> list.map(fn(row) {
    row
    |> io.debug
  })

  let _ = elli.become(my_service, on_port: port)

  Nil
}

// Define a HTTP service
//
pub fn my_service(
  _req: request.Request(t),
) -> response.Response(bytes_builder.BytesBuilder) {
  let body =
    Message("Hello from secret_gleam!")
    |> message_to_json
    |> bytes_builder.from_string

  response.new(200)
  |> response.prepend_header("made-with", "Gleam")
  |> response.prepend_header("content-type", "application/json")
  |> response.set_body(body)
}
