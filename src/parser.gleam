import gleam/function.{curry3}
import nibble.{
  backtrackable, commit, drop, eof, keep, loop, one_of, string, succeed,
  take_until, take_while, then, whitespace,
}
import parser/attributes.{Attributes, attributes}
import gleam/list
import gleam/string

pub type Children =
  List(Token)

fn trailing_tag(
  children: Children,
) -> nibble.Parser(nibble.Loop(List(Token), a), b) {
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
pub fn void_element() -> nibble.Parser(Token, a) {
  backtrackable(
    succeed(curry3(HtmlElement))
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

pub fn element() -> nibble.Parser(Token, a) {
  backtrackable(
    succeed(curry3(HtmlElement))
    // Tag name
    |> drop(whitespace())
    |> drop(string("<"))
    |> keep(take_until(fn(c) { c == " " || c == "/" || c == ">" }))
    |> drop(whitespace())
    // Attributes
    |> keep(attributes())
    |> drop(whitespace())
    |> keep(children())
    |> drop(whitespace()),
  )
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
        bracketed_block()
        |> nibble.map(fn(child) { nibble.Continue([child, ..children]) }),
        html()
        |> nibble.map(fn(child) { nibble.Continue([child, ..children]) })
        |> drop(whitespace()),
      ])
    },
  )
}

pub fn bracketed_block() {
  backtrackable(
    succeed(Gleam)
    |> drop(whitespace())
    |> drop(string("{"))
    |> keep(take_while(fn(c) { c != "}" }))
    |> drop(string("}"))
    |> drop(whitespace()),
  )
}

pub fn text() -> nibble.Parser(Token, a) {
  backtrackable(
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
    |> drop(whitespace()),
  )
}

pub fn html() -> nibble.Parser(Token, a) {
  one_of([void_element(), element(), text()])
}

pub type Token {
  Gleam(String)
  Text(String)
  HtmlElement(tag_name: String, attributes: Attributes, children: Children)
}

pub fn gleam_code() -> nibble.Parser(Token, a) {
  succeed(Gleam)
  |> drop(whitespace())
  |> keep(take_while(fn(c) { c != ">" }))
}

pub fn token() -> nibble.Parser(Token, a) {
  one_of([
    gleam_code()
    |> drop(string(">->")),
    html()
    |> drop(string("<-<")),
    gleam_code(),
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
        |> nibble.map(fn(el) {
          // io.debug(el)
          nibble.Continue([el, ..tokens])
        })
        |> drop(whitespace()),
      ])
    },
  )
}

pub fn parse(input: String) -> Result(List(Token), List(nibble.DeadEnd(a))) {
  nibble.run(input, tokens())
}
