import gleam/javascript/array

pub external fn stdin() -> String =
  "./native.mjs" "stdin"

pub external fn test() -> Result(String, String) =
  "./native.mjs" "test"

pub external fn format(code: String) -> Result(String, String) =
  "./native.mjs" "format"

pub external fn args() -> array.Array(String) =
  "./native.mjs" "args"

pub external fn read_file(path: String) -> String =
  "./native.mjs" "read_file"

pub external fn base_name(path: String) -> String =
  "./native.mjs" "base_name"

pub external fn dirname(path: String) -> String =
  "./native.mjs" "dirname"

pub external fn write_file(path: String, contents: String) -> Nil =
  "./native.mjs" "write_file"

pub external fn watch(
  paths: array.Array(String),
  callback: fn(String) -> Result(Nil, String),
) -> Nil =
  "./native.mjs" "watch"
