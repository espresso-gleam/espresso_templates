import gleam/function.{curry2}
import nibble.{
  backtrackable, commit, drop, eof, grapheme, int, keep, loop, many, map, one_of,
  spaces, string, succeed, take_until, take_while, then, whitespace,
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

/// Parses a list of attributes
/// class="stuff" id="thing" -> [Attribute("id", "thing"), Attribute("class", "stuff")]
pub fn attributes() {
  loop(
    [],
    fn(attrs) {
      nibble.one_of([
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
  succeed(function.curry2(Attribute))
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
  succeed(function.curry3(Element))
  // Tag name
  |> drop(whitespace())
  |> drop(string("<"))
  |> keep(take_until(fn(c) { c == " " || c == ">" }))
  |> drop(whitespace())
  // Attributes
  |> keep(attributes())
  |> drop(whitespace())
  |> keep(children())
}

pub fn text() -> nibble.Parser(Element, a) {
  succeed(Text)
  |> drop(whitespace())
  |> keep(take_while(fn(c) { c != "<" }))
  |> drop(whitespace())
}

pub fn document() -> nibble.Parser(Element, a) {
  one_of([import_block(), comment(), element(), text()])
}

pub fn documents() -> nibble.Parser(List(Element), a) {
  loop(
    [],
    fn(documents) {
      one_of([
        eof()
        |> nibble.replace(list.reverse(documents))
        |> nibble.map(nibble.Break),
        one_of([import_block(), comment(), element(), text()])
        |> nibble.map(fn(el) { { nibble.Continue([el, ..documents]) } })
        |> drop(whitespace()),
      ])
    },
  )
}

pub fn main() {
  let parser = attribute()
  case nibble.run("class=\"text-black\"", parser) {
    Ok(point) -> {
      io.debug(point)
      ""
    }
    Error(error) -> {
      io.debug(error)
      ""
    }
  }
}
