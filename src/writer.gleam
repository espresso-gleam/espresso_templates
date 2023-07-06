import gleam/list
import gleam/io
import gleam/string_builder.{StringBuilder}
import parser.{Block, Comment, Element, Import, Text}
import system.{format}

pub fn element_to_function_body(
  document: StringBuilder,
  element: Element,
) -> StringBuilder {
  case element {
    Text(text) -> string_builder.append(document, "txt(\"" <> text <> "\")")
    Comment(text) -> string_builder.append(document, "// " <> text)
    Block(block) -> string_builder.append(document, block)
    Element(tag_name, attributes, children) -> {
      let document =
        document
        |> render_tag(tag_name)
        |> render_attributes(attributes)
        |> string_builder.append(" |> c([")

      let children =
        list.map(
          children,
          fn(child) {
            case child {
              Block(_) -> element_to_function_body(string_builder.new(), child)
              _ ->
                element_to_function_body(string_builder.new(), child)
                |> string_builder.append(",")
            }
          },
        )
        |> string_builder.join("")

      document
      |> string_builder.append_builder(children)
      |> string_builder.append("])")
    }

    _ -> document
  }
}

fn render_tag(document: StringBuilder, tag_name: String) -> StringBuilder {
  string_builder.append(document, "t(\"" <> tag_name <> "\")")
}

fn render_attributes(
  document: StringBuilder,
  attributes: List(parser.Attribute),
) -> StringBuilder {
  list.fold(
    attributes,
    document,
    fn(document, attr) {
      string_builder.append(
        document,
        " |> a(\"" <> attr.name <> "\", \"" <> attr.value <> "\")",
      )
    },
  )
}

pub fn gather_imports(elements: List(Element), imports: String) -> String {
  case elements {
    [] -> imports
    [Import(block), ..rest] -> {
      let new_imports = imports <> block <> "\n"
      gather_imports(rest, new_imports)
    }
    [_, ..rest] -> gather_imports(rest, imports)
  }
}

pub fn to_gleam(input: String) -> Result(String, String) {
  let result = parser.parse(input)
  case result {
    Ok(documents) -> {
      let fun =
        string_builder.new()
        |> string_builder.append("import espresso/html.{t,c,a,txt}\n")
        |> string_builder.append(gather_imports(documents, ""))
        |> string_builder.append("pub fn render(params: Params) {\n")

      documents
      |> list.fold(fun, element_to_function_body)
      |> string_builder.append("\n}")
      |> string_builder.to_string()
      |> format()
    }

    Error(e) -> {
      io.debug(e)
      Error("Could not parse input to gleam")
    }
  }
}
