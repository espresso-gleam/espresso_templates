import gleam/javascript/array

@external(javascript, "./native.mjs", "stdin")
pub fn stdin() -> String

@external(javascript, "./native.mjs", "format")
pub fn format(code code: String) -> Result(String, String)

@external(javascript, "./native.mjs", "args")
pub fn args() -> array.Array(String)

@external(javascript, "./native.mjs", "read_file")
pub fn read_file(path path: String) -> String

@external(javascript, "./native.mjs", "base_name")
pub fn base_name(path path: String) -> String

@external(javascript, "./native.mjs", "dirname")
pub fn dirname(path path: String) -> String

@external(javascript, "./native.mjs", "write_file")
pub fn write_file(path path: String, contents contents: String) -> Nil

@external(javascript, "./native.mjs", "watch")
pub fn watch(paths paths: array.Array(String), callback callback: fn(String) ->
    Result(Nil, String)) -> Nil
