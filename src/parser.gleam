import gleam/function.{curry2, curry3}
import nibble.{
  backtrackable, commit, drop, eof, keep, loop, one_of, string, succeed,
  take_until, take_while, then, whitespace,
}
import gleam/list
import gleam/string

pub type Attribute {
  Attribute(name: String, value: String)
}

pub type Attributes =
  List(Attribute)

pub type Children =
  List(Element)

pub type Element {
  DocTypeDeclaration
  Text(String)
  Element(tag_name: String, attributes: Attributes, children: Children)
  Comment(String)
  Import(String)
  Block(String)
  OpeningScope(header: String, children: Children)
  ClosingScope(String)
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

pub fn quoted_block() {
  backtrackable(
    succeed(Block)
    |> drop(whitespace())
    |> drop(string("<%"))
    |> drop(whitespace())
    |> keep(
      take_while(fn(c) { c != "%" })
      |> then(fn(block) {
        block
        |> string.trim()
        |> commit()
      }),
    )
    |> drop(string("%>")),
  )
}

pub fn opening_scope() {
  backtrackable(
    succeed(curry2(OpeningScope))
    |> drop(whitespace())
    |> drop(string("<%"))
    |> drop(whitespace())
    |> keep(
      take_while(fn(c) { c != "{" })
      |> then(fn(block) { commit(block <> "{") }),
    )
    |> drop(string("{"))
    |> drop(whitespace())
    |> drop(string("%>"))
    |> drop(whitespace())
    |> keep(children())
    |> drop(whitespace()),
  )
}

pub fn closing_scope() {
  backtrackable(
    succeed(ClosingScope)
    |> drop(whitespace())
    |> drop(string("<%"))
    |> drop(whitespace())
    |> keep(
      take_while(fn(c) { c == "}" || c == ")" || c == " " })
      |> then(fn(block) {
        block
        |> string.trim()
        |> commit()
      }),
    )
    |> drop(whitespace())
    |> drop(string("%>"))
    |> drop(whitespace()),
  )
}

pub fn doc_type_declaration() {
  succeed(DocTypeDeclaration)
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
      one_of([
        one_of([string("/"), string(">"), eof()])
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

fn trailing_tag(
  children: Children,
) -> nibble.Parser(nibble.Loop(List(Element), a), b) {
  string("</")
  |> nibble.replace(list.reverse(children))
  |> nibble.map(nibble.Break)
  |> drop(take_while(fn(c) { c != ">" }))
  |> drop(string(">"))
  |> drop(whitespace())
}

/// void_element parses elements that have no children
/// 
/// https://developer.mozilla.org/en-US/docs/Glossary/Void_element
pub fn void_element() {
  backtrackable(
    succeed(curry3(Element))
    // Tag name
    |> drop(whitespace())
    |> drop(string("<"))
    |> keep(one_of(void_elements()))
    |> drop(whitespace())
    // Attributes
    |> keep(attributes())
    |> drop(whitespace())
    |> drop(one_of([
      string("/>")
      |> drop(whitespace()),
      string(">")
      |> drop(whitespace()),
      whitespace(),
    ]))
    |> keep(commit([]))
    |> drop(whitespace()),
  )
}

pub fn void_elements() {
  [
    "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta",
    "param", "source", "track", "wbr",
  ]
  |> list.map(fn(el: String) -> nibble.Parser(String, a) {
    string(el)
    |> nibble.map(fn(_) { el })
  })
}

pub fn element() {
  succeed(curry3(Element))
  // Tag name
  |> drop(whitespace())
  |> drop(string("<"))
  |> keep(take_until(fn(c) { c == " " || c == "/" || c == ">" }))
  |> drop(whitespace())
  // Attributes
  |> keep(attributes())
  |> drop(whitespace())
  |> keep(children())
  |> drop(whitespace())
}

pub fn children() {
  loop(
    [],
    fn(children) {
      one_of([
        trailing_tag(children),
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

pub fn text() -> nibble.Parser(Element, a) {
  succeed(Text)
  |> drop(whitespace())
  |> keep(
    take_while(fn(c) { c != "<" })
    |> then(fn(comment) {
      comment
      |> string.trim()
      |> commit()
    }),
  )
  |> drop(whitespace())
}

pub fn document() -> nibble.Parser(Element, a) {
  one_of([
    doc_type_declaration(),
    import_block(),
    comment(),
    html_comment(),
    opening_scope(),
    closing_scope(),
    quoted_block(),
    // Void is backtrackable, if it fails it will rollback and try element
    void_element(),
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

pub fn parse(input: String) -> Result(List(Element), List(nibble.DeadEnd(a))) {
  nibble.run(input, documents())
}
