import gleam/list
import gleam/io
import gleam/string_builder.{StringBuilder}
import parser.{Children, Gleam, HtmlElement, Text, Token}
import system.{format}

pub fn token_to_function_body(
  document: StringBuilder,
  token: Token,
) -> StringBuilder {
  case token {
    HtmlElement(tag_name, attributes, children) -> {
      document
      |> render_tag(tag_name)
      |> render_attributes(attributes)
      |> render_children(children)
    }
    Text(text) -> string_builder.append(document, text)
    Gleam(raw) -> string_builder.append(document, raw)
  }
}

fn render_children(document: StringBuilder, children: Children) -> StringBuilder {
  case children {
    [] -> string_builder.append(document, " |> c([])")
    children -> {
      let document = string_builder.append(document, " |> c([")

      let rendered_children =
        list.map(
          children,
          fn(child) {
            string_builder.new()
            |> token_to_function_body(child)
            |> string_builder.append(", ")
          },
        )
        |> string_builder.join("")

      document
      |> string_builder.append_builder(rendered_children)
      |> string_builder.append("])")
    }
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

pub fn to_gleam(input: String) -> Result(String, String) {
  let result = parser.parse(input)
  case result {
    Ok(blocks) -> {
      blocks
      |> list.fold(string_builder.new(), token_to_function_body)
      |> string_builder.to_string()
      |> format()
    }

    Error(e) -> {
      io.debug(e)
      Error("Could not parse input to gleam")
    }
  }
}
