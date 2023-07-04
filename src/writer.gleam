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
        string_builder.append(document, "t(\"" <> tag_name <> "\")")

      let document =
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

      case children {
        [] -> document
        children -> {
          let document = string_builder.append(document, " |> c([")
          list.fold(
            children,
            document,
            fn(document, child) {
              case child {
                Block(_) -> element_to_function_body(document, child)
                Element(_, _, []) -> element_to_function_body(document, child)
                Element(_, _, [Block(_)]) ->
                  element_to_function_body(document, child)
                _ -> {
                  document
                  |> element_to_function_body(child)
                  |> string_builder.append(", ")
                }
              }
            },
          )
          |> string_builder.append("])")
        }
      }
    }

    _ -> document
  }
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

      let out =
        documents
        |> list.fold(fun, element_to_function_body)
        |> string_builder.append("\n}")
        |> string_builder.to_string()
        |> format()
      Ok(out)
    }

    Error(error) -> {
      io.debug(error)
      Error("Could not parse input to gleam")
    }
  }
}
