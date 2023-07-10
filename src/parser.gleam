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
  Text(String)
  Element(tag_name: String, attributes: Attributes, children: Children)
}

pub type Document =
  List(Token)

pub type Token {
  GleamCode(String)
  GHPElement
}

pub fn code_parser() {
  one_of([gleam_code(), ghp_element()])
}

pub fn gleam_code() {
  succeed(GleamCode)
  |> drop(whitespace())
  |> drop(string(">->"))
}

pub fn ghp_element() {
  succeed(curry3(Element))
  |> drop(whitespace())
  |> keep(documents())
  |> drop(whitespace())
  |> drop(string("<-<"))
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
    // Void is backtrackable, if it fails it will rollback and try element
    void_element(),
    element(),
    text(),
  ])
}

pub fn tokens() -> nibble.Parser(List(Token), a) {
  loop(
    [],
    fn(tokens) {
      one_of([
        eof()
        |> nibble.replace(list.reverse(tokens))
        |> nibble.map(nibble.Break),
        token()
        |> nibble.map(fn(el) { { nibble.Continue([el, ..tokens]) } })
        |> drop(whitespace()),
      ])
    },
  )
}

pub fn parse(input: String) -> Result(List(Token), List(nibble.DeadEnd(a))) {
  nibble.run(input, tokens())
}
