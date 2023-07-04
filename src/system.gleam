import gleam/javascript/array

pub external fn stdin() -> String =
  "./native.js" "stdin"

pub external fn format(code: String) -> String =
  "./native.js" "format"

pub external fn args() -> array.Array(String) =
  "./native.js" "args"

pub external fn read_file(path: String) -> String =
  "./native.js" "read_file"

pub external fn base_name(path: String) -> String =
  "./native.js" "base_name"

pub external fn write_file(path: String, contents: String) -> Nil =
  "./native.js" "write_file"
