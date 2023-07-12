import gleam/list
import gleam/io
import gleam/string_builder.{StringBuilder}
import parser
import parser/grammar.{Block, GHP, GleamBlock, Grammar, HtmlElement, Text}
import parser/elements.{Children}
import parser/attributes.{Attribute, GleamAttribute}
import system.{format}

pub fn render_block_grammar(
  document: StringBuilder,
  grammar: Grammar,
) -> StringBuilder {
  case grammar {
    Block(gleam, children) -> {
      let header = string_builder.append(document, gleam)
      render_block_children(header, children)
    }
    Text(str) -> string_builder.append(document, str)
    GHP(_) -> document
    GleamBlock(_) -> document
    HtmlElement(_, _, _) -> document
  }
}

fn render_block_children(document: StringBuilder, children: List(Grammar)) {
  list.fold(
    children,
    document,
    fn(doc, child) {
      case child {
        GHP([HtmlElement(tag_name, attributes, children)]) ->
          document
          |> render_tag(tag_name)
          |> render_attributes(attributes)
          |> render_children(children)
        Text(str) -> string_builder.append(doc, str)
        Block(_, _) -> doc
        GHP(_) -> doc
        GleamBlock(_) -> doc
        HtmlElement(_, _, _) -> doc
      }
    },
  )
}

pub fn render_html_grammar(
  document: StringBuilder,
  grammar: Grammar,
) -> StringBuilder {
  case grammar {
    HtmlElement(tag_name, attributes, children) -> {
      document
      |> string_builder.append("html.c([")
      |> render_tag(tag_name)
      |> render_attributes(attributes)
      |> render_children(children)
      |> string_builder.append("])")
    }
    Text(text) ->
      document
      |> string_builder.append("html.c([html.txt(\"")
      |> string_builder.append(text)
      |> string_builder.append("\")])")
    Block(_, _) -> document
    GHP(_) -> document
    GleamBlock(block) ->
      document
      |> string_builder.append("html.dyn({")
      |> render_block_grammar(block)
      |> string_builder.append("})")
  }
}

fn render_children(document: StringBuilder, children: Children) -> StringBuilder {
  case children {
    [] -> document
    _ ->
      document
      |> string_builder.append(" |> ")
      |> string_builder.append_builder(
        children
        |> list.map(fn(child) {
          render_html_grammar(string_builder.new(), child)
        })
        |> string_builder.join(" |> "),
      )
  }
}

fn render_tag(document: StringBuilder, tag_name: String) -> StringBuilder {
  string_builder.append(document, "html.t(\"" <> tag_name <> "\")")
}

fn render_attributes(
  document: StringBuilder,
  attributes: List(Attribute),
) -> StringBuilder {
  list.fold(
    attributes,
    document,
    fn(document, attr) {
      case attr {
        Attribute(name, value) ->
          string_builder.append(
            document,
            " |> html.a(\"" <> name <> "\", \"" <> value <> "\")",
          )
        GleamAttribute(name, value) ->
          string_builder.append(
            document,
            " |> html.a(\"" <> name <> "\", " <> value <> ")",
          )
      }
    },
  )
}

pub fn to_gleam(input: String) -> Result(String, String) {
  let result = parser.parse(input)
  case result {
    Ok(grammar) -> {
      string_builder.new()
      |> render_block_grammar(grammar)
      |> string_builder.to_string()
      |> format()
    }

    Error(e) -> {
      io.debug(e)
      Error("Could not parse input to gleam")
    }
  }
}
