import gleam/io
import gleam/list
import gleam/javascript/array
import gleam/string
import glint.{CommandInput}
import glint/flag
import system.{args, base_name, dirname, read_file, write_file}
import writer

fn watch(input: CommandInput) {
  case flag.get_string(from: input.flags, for: "files") {
    Ok("") ->
      ["**/*.ghp"]
      |> array.from_list()
      |> system.watch(convert_file)
    Ok(files) ->
      [files]
      |> array.from_list()
      |> system.watch(convert_file)
    _ -> {
      io.debug("Invalid watch usage")
      Nil
    }
  }
}

fn convert_file(path: String) -> Result(Nil, String) {
  let contents = read_file(path)
  case writer.to_gleam(contents) {
    Ok(parsed) -> {
      let filename = dirname(path) <> "/" <> base_name(path) <> ".gleam"
      write_file(filename, parsed)
      Ok(Nil)
    }
    Error(e) -> {
      io.println(e)
      Error(e)
    }
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
  let files_flag =
    flag.new(flag.S)
    |> flag.description("File pattern to watch")

  let args =
    args()
    |> array.to_list()
  glint.new()
  |> glint.add(
    at: ["watch"],
    do: glint.command(watch)
    |> glint.description(
      "Watches all files matching given pattern i.e. espresso_templatizer watch asrc/**/*.ghp",
    )
    |> glint.flag("files", files_flag),
  )
  |> glint.add(
    at: ["convert"],
    do: glint.command(convert)
    |> glint.description("Converts individual ghp files into gleam"),
  )
  |> glint.run(args)
}
