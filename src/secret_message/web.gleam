import gleam/bit_array
import gleam/bytes_builder
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/http/response
import gleam/http/service
import gleam/result
import gleam/string
import secret_message/web/logger

fn reply(request) {
  let content_type =
    request
    |> request.get_header("content-type")
    |> result.unwrap("application/octet-stream")

  response.new(200)
  |> response.set_body(request.body)
  |> response.prepend_header("content-type", content_type)
}

fn not_found() {
  let body =
    "There's nothing here. Try POSTing to /echo"
    |> bit_array.from_string

  response.new(404)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/plain")
}

fn hello(name) {
  let reply = case string.lowercase(name) {
    "mike" -> "Hello, Joe!"
    _ -> string.concat(["Hello, ", name, "!"])
  }

  response.new(200)
  |> response.set_body(bit_array.from_string(reply))
  |> response.prepend_header("content-type", "text/plain")
}

pub fn service(request) {
  let path = request.path_segments(request)

  case request.method, path {
    Post, ["echo"] -> reply(request)
    Get, ["hello", name] -> hello(name)
    _, _ -> not_found()
  }
}

pub fn stack() {
  service
  |> service.prepend_response_header("made-with", "Gleam")
  |> service.map_response_body(bytes_builder.from_bit_array)
  |> logger.middleware
}
