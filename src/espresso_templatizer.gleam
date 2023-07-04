import gleam/io
import gleam/list
import gleam/javascript/array
import gleam/string
import glint.{CommandInput}
import glint/flag
import system.{args, base_name, read_file, write_file}
import writer

fn watch(input: CommandInput) {
  let assert Ok(flag.S(dir)) = flag.get(from: input.flags, for: "dir")
  dir
  |> io.println()
}

fn convert_file(path: String) -> Result(Nil, String) {
  let contents = read_file(path)
  case writer.to_gleam(contents) {
    Ok(parsed) -> {
      write_file(base_name(path) <> ".gleam", parsed)
      Ok(Nil)
    }
    _ -> Error("Failed to parse file")
  }
}

fn convert(input: CommandInput) -> Nil {
  case input.args {
    [] -> {
      io.println("At least one file is required.")
    }

    files -> {
      list.each(files, convert_file)
      io.println("Converted files: " <> string.join(files, ", "))
    }
  }
}

pub fn main() {
  let args =
    args()
    |> array.to_list()

  glint.new()
  |> glint.add_command(
    at: ["watch"],
    do: watch,
    with: [flag.string("dir", "src", "the directory to watch, defaults to src")],
    described: "Watches the given directory for *.ghp file changes",
  )
  |> glint.add_command(
    at: ["convert"],
    do: convert,
    with: [],
    described: "Converts individual ghp files into gleam",
  )
  |> glint.run(args)
}
