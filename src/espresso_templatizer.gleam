import gleam/function.{curry2, curry3}
import nibble.{
  commit, drop, eof, keep, loop, one_of, string, succeed, take_until, take_while,
  then, whitespace,
}
import gleam/list
import gleam/io
import gleam/string

pub type Attribute {
  Attribute(name: String, value: String)
}

pub type Attributes =
  List(Attribute)

type Children =
  List(Element)

pub type Element {
  Preamble
  Text(String)
  Element(tag_name: String, attributes: Attributes, children: Children)
  Comment(String)
  Import(String)
}

pub fn comment() {
  succeed(Comment)
  |> drop(whitespace())
  |> drop(string("<%%"))
  |> drop(whitespace())
  |> keep(
    take_while(fn(c) { c != "%" })
    |> then(fn(comment) {
      comment
      |> string.trim()
      |> commit()
    }),
  )
  |> drop(string("%%>"))
}

pub fn html_comment() {
  succeed(Comment)
  |> drop(whitespace())
  |> drop(string("<!"))
  |> drop(take_while(fn(c) { c == "-" }))
  |> drop(whitespace())
  |> keep(
    take_while(fn(c) { c != "-" })
    |> then(fn(comment) {
      comment
      |> string.trim()
      |> commit()
    }),
  )
  |> drop(string("-->"))
}

pub fn import_block() {
  succeed(Import)
  |> drop(whitespace())
  |> drop(string("<%^"))
  |> drop(whitespace())
  |> keep(
    take_while(fn(c) { c != "^" })
    |> then(fn(comment) {
      comment
      |> string.trim()
      |> commit()
    }),
  )
  |> drop(string("^%>"))
}

pub fn preamble() {
  succeed(Preamble)
  |> drop(whitespace())
  |> drop(string("<!DOCTYPE html>"))
  |> drop(whitespace())
}

/// Parses a list of attributes
/// class="stuff" id="thing" -> [Attribute("id", "thing"), Attribute("class", "stuff")]
pub fn attributes() {
  loop(
    [],
    fn(attrs) {
      nibble.one_of([
        string("/>")
        |> nibble.replace(list.reverse(attrs))
        |> nibble.map(nibble.Break),
        string(">")
        |> nibble.replace(list.reverse(attrs))
        |> nibble.map(nibble.Break),
        eof()
        |> nibble.replace(list.reverse(attrs))
        |> nibble.map(nibble.Break),
        nibble.map(
          attribute(),
          fn(attribute) { nibble.Continue([attribute, ..attrs]) },
        ),
      ])
    },
  )
}

/// Parses html attributes
/// class="stuff" -> Attribute("class", "stuff")
pub fn attribute() -> nibble.Parser(Attribute, a) {
  succeed(curry2(Attribute))
  |> drop(whitespace())
  |> keep(take_while(fn(c) { c != "=" }))
  |> drop(string("=\""))
  |> keep(take_while(fn(c) { c != "\"" }))
  |> drop(string("\""))
  |> drop(whitespace())
}

pub fn children() {
  loop(
    [],
    fn(children) {
      one_of([
        string("/>")
        |> nibble.replace(list.reverse(children))
        |> nibble.map(nibble.Break),
        string("</")
        |> nibble.replace(list.reverse(children))
        |> nibble.map(nibble.Break)
        |> drop(take_while(fn(c) { c != ">" }))
        |> drop(string(">")),
        eof()
        |> nibble.replace(list.reverse(children))
        |> nibble.map(nibble.Break),
        document()
        |> nibble.map(fn(child) { { nibble.Continue([child, ..children]) } })
        |> drop(whitespace()),
      ])
    },
  )
}

pub fn element() {
  succeed(curry3(Element))
  // Tag name
  |> drop(whitespace())
  |> drop(string("<"))
  |> keep(take_until(fn(c) { c == " " || c == ">" }))
  |> drop(whitespace())
  // Attributes
  |> keep(attributes())
  |> drop(whitespace())
  |> keep(one_of([nibble.replace(string("/>"), []), children()]))
}

pub fn text() -> nibble.Parser(Element, a) {
  succeed(Text)
  |> drop(whitespace())
  |> keep(take_while(fn(c) { c != "<" }))
  |> drop(whitespace())
}

pub fn document() -> nibble.Parser(Element, a) {
  one_of([
    preamble(),
    import_block(),
    comment(),
    html_comment(),
    element(),
    text(),
  ])
}

pub fn documents() -> nibble.Parser(List(Element), a) {
  loop(
    [],
    fn(documents) {
      one_of([
        eof()
        |> nibble.replace(list.reverse(documents))
        |> nibble.map(nibble.Break),
        document()
        |> nibble.map(fn(el) { { nibble.Continue([el, ..documents]) } })
        |> drop(whitespace()),
      ])
    },
  )
}

pub fn element_to_function_body(element: Element) -> String {
  case element {
    Text(text) -> "txt(\"" <> text <> "\")"
    Comment(text) -> "// " <> text
    Element(tag_name, attributes, children) -> {
      let tag = "t(\"" <> tag_name <> "\")"

      let attrs =
        list.map(
          attributes,
          fn(attr) {
            " |> a(\"" <> attr.name <> "\", \"" <> attr.value <> "\")"
          },
        )
        |> string.join("")

      let children =
        list.map(children, element_to_function_body)
        |> string.join(", ")
      tag <> attrs <> "|> c([" <> children <> "])"
    }
    _ -> ""
  }
}

pub external fn stdin() -> String =
  "./os.js" "stdin"

pub fn main() {
  let input = stdin()
  let result = nibble.run(input, documents())
  case result {
    Ok(documents) -> {
      documents
      |> list.map(element_to_function_body)
      |> string.join("\n")
      |> io.println()
    }
    Error(error) -> {
      io.debug(error)
      io.println("")
    }
  }
}
