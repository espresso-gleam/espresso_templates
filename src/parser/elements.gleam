import gleam/function.{curry3}
import gleam/list
import nibble.{
  backtrackable, commit, drop, eof, keep, loop, one_of, string, succeed,
  take_until, take_while, then, whitespace,
}
import parser/attributes.{attributes}
import parser/grammar.{Grammar, HtmlElement, Text}
import gleam/string

/// void_element parses elements that have no children
/// 
/// https://developer.mozilla.org/en-US/docs/Glossary/Void_element
pub fn void_element() -> nibble.Parser(Grammar, a) {
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

fn void_elements() {
  [
    "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta",
    "param", "source", "track", "wbr",
  ]
  |> list.map(fn(el: String) -> nibble.Parser(String, a) {
    string(el)
    |> nibble.map(fn(_) { el })
  })
}

pub fn element() -> nibble.Parser(Grammar, a) {
  backtrackable(
    succeed(curry3(HtmlElement))
    // Tag name
    |> drop(whitespace())
    |> drop(string("<"))
    |> keep(take_until(fn(c) { c == " " || c == ">" }))
    |> drop(whitespace())
    // Attributes
    |> keep(attributes())
    |> drop(whitespace())
    |> keep(children())
    |> drop(whitespace()),
  )
}

fn trailing_tag() {
  whitespace()
  |> drop(string("</"))
  |> drop(take_while(fn(c) { c != ">" }))
  |> drop(string(">"))
  |> drop(whitespace())
}

pub fn elements() -> nibble.Parser(Grammar, a) {
  one_of([void_element(), element(), text()])
}

pub fn text() {
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

pub type Children =
  List(Grammar)

pub fn children() {
  loop(
    [],
    fn(children) {
      one_of([
        trailing_tag()
        |> nibble.replace(list.reverse(children))
        |> nibble.map(nibble.Break),
        eof()
        |> nibble.replace(list.reverse(children))
        |> nibble.map(nibble.Break),
        elements()
        |> nibble.map(fn(child) { nibble.Continue([child, ..children]) })
        |> drop(whitespace()),
      ])
    },
  )
}
