import dot_env
import dot_env/env
import gleam/io

pub fn main() {
  io.println("Hello from secret_gleam!")

  dot_env.load()

  case env.get("TESTVAR") {
    Ok(value) -> io.println(value)
    Error(_) -> io.println("something went wrong")
  }

  Nil
}
