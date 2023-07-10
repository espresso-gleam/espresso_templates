import gleam/list
import gleam/io
import gleam/string_builder.{StringBuilder}
import parser.{
  Attr, Block, BlockAttr, Children, ClosingScope, Comment, Element, Import,
  OpeningScope, Text,
}
import system.{format}

pub fn element_to_function_body(
  document: StringBuilder,
  element: Element,
) -> StringBuilder {
  case element {
    OpeningScope(block, children) -> {
      list.fold(
        children,
        string_builder.append(document, block),
        element_to_function_body,
      )
    }
    ClosingScope(block) -> string_builder.append(document, block)
    Block(block) -> string_builder.append(document, block)
    Comment(text) -> string_builder.append(document, "// " <> text)
    Element(tag_name, attributes, children) -> {
      document
      |> render_tag(tag_name)
      |> render_attributes(attributes)
      |> render_children(children)
    }
    Text(text) -> string_builder.append(document, "txt(\"" <> text <> "\")")

    _ -> document
  }
}

fn render_children(document: StringBuilder, children: Children) -> StringBuilder {
  case children {
    [] -> string_builder.append(document, " |> c([])")
    children -> {
      let rendered_children =
        list.map(
          children,
          fn(child) {
            string_builder.new()
            |> element_to_function_body(child)
            |> string_builder.append(", ")
          },
        )
        |> string_builder.join("")

      // If the first and last child are an open and closing scope do not render the 
      // wrapping [] because it errors the formatter, i.e. return this: "c(inner code here)"
      case list.first(children) {
        Ok(OpeningScope(_, scope_children)) -> {
          case list.last(scope_children) {
            Ok(ClosingScope(_)) ->
              append_children(document, False, rendered_children)

            _ -> append_children(document, True, rendered_children)
          }
        }

        _ -> append_children(document, True, rendered_children)
      }
    }
  }
}

fn append_children(
  document: StringBuilder,
  brackets: Bool,
  rendered_children: StringBuilder,
) -> StringBuilder {
  case brackets {
    True ->
      document
      |> string_builder.append(" |> c([")
      |> string_builder.append_builder(rendered_children)
      |> string_builder.append("])")
    False ->
      document
      |> string_builder.append(" |> c(")
      |> string_builder.append_builder(rendered_children)
      |> string_builder.append(")")
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
      let value = case attr.value {
        Attr(a) -> "\"" <> a <> "\""
        BlockAttr(block) -> block
      }

      string_builder.append(
        document,
        " |> a(\"" <> attr.name <> "\", " <> value <> ")",
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

type Imports {
  Imports(a: Bool, c: Bool, t: Bool, txt: Bool)
}

fn used_imports(elements: List(Element), imports: Imports) -> Imports {
  case imports {
    Imports(a: True, c: True, t: True, txt: True) -> imports
    _ -> {
      case elements {
        [] -> imports
        [im, ..rest] -> {
          let has_tag =
            imports.t || case im {
              Element(_, _, _) -> True
              _ -> imports.t
            }
          let has_attrs =
            imports.a || case im {
              Element(_, [_, ..], _) -> True
              _ -> imports.a
            }

          case im {
            Text(_) ->
              used_imports(
                rest,
                Imports(txt: True, t: has_tag, a: has_attrs, c: has_tag),
              )
            Element(_, _, children) ->
              used_imports(
                children,
                Imports(..imports, t: has_tag, a: has_attrs, c: has_tag),
              )
            _ -> used_imports(rest, imports)
          }
        }
      }
    }
  }
}

fn import_to_string(imports: Imports) -> StringBuilder {
  let str =
    string_builder.append(string_builder.new(), "import espresso/html.{")

  let str = case imports.a {
    True -> string_builder.append(str, "a,")
    False -> str
  }

  let str = case imports.c {
    True -> string_builder.append(str, "c,")
    False -> str
  }

  let str = case imports.t {
    True -> string_builder.append(str, "t,")
    False -> str
  }

  let str = case imports.txt {
    True -> string_builder.append(str, "txt,")
    False -> str
  }

  string_builder.append(str, "}\n")
}

pub fn to_gleam(input: String) -> Result(String, String) {
  let result = parser.parse(input)
  case result {
    Ok(documents) -> {
      let imports =
        used_imports(
          documents,
          Imports(a: False, c: False, t: False, txt: False),
        )

      let fun =
        string_builder.new()
        |> string_builder.append_builder(import_to_string(imports))
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
