import gleam/function.{curry2, curry3}
import gleam/list
import nibble.{
  backtrackable, commit, drop, eof, keep, loop, one_of, string, succeed,
  take_until, take_while, whitespace,
}
import parser/attributes.{attributes}
import parser/grammar.{Block, GHP, GleamBlock, Grammar, HtmlElement, Text}

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
  |> keep(take_while(fn(c) { c != "<" && c != "{" }))
  |> drop(whitespace())
}

fn balance_braces(count: Int, current: String) -> nibble.Parser(Grammar, a) {
  nibble.one_of([
    nibble.string("}")
    |> nibble.then(fn(_c) {
      case count {
        1 ->
          // we've balanced the braces, so return the collected string
          case nibble.run(current, full_block()) {
            Ok(result) -> {
              nibble.succeed(result)
            }
            Error(_) -> {
              nibble.succeed(Text(current))
            }
          }

        _ ->
          // still more closing braces to find
          balance_braces(count - 1, current <> "}")
      }
    }),
    nibble.string("{")
    |> nibble.then(fn(_c) {
      // we've found an opening brace, increase the count
      balance_braces(count + 1, current <> "{")
    }),
    nibble.any()
    |> nibble.then(fn(c) {
      // add the character to the string and continue
      balance_braces(count, current <> c)
    }),
    nibble.eof()
    |> nibble.then(fn(_) {
      case count {
        0 -> nibble.succeed(Text(current))
        _ -> nibble.fail("Unbalanced braces")
      }
    }),
  ])
}

fn gleam_block() -> nibble.Parser(Grammar, a) {
  nibble.succeed(GleamBlock)
  |> nibble.drop(nibble.string("{"))
  |> nibble.keep(balance_braces(1, ""))
  // start with a count of 1 since we've consumed an open brace
  // this will consume the closing brace
  |> nibble.drop(nibble.whitespace())
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
        gleam_block()
        |> nibble.map(fn(child) { nibble.Continue([child, ..children]) })
        |> drop(whitespace()),
        elements()
        |> nibble.map(fn(child) { nibble.Continue([child, ..children]) })
        |> drop(whitespace()),
      ])
    },
  )
}

pub fn opening_tag() {
  whitespace()
  |> drop(string(">->"))
  |> drop(whitespace())
}

pub fn closing_tag() {
  whitespace()
  |> drop(string("<-<"))
  |> drop(whitespace())
}

pub fn ghp() -> nibble.Parser(Grammar, a) {
  succeed(GHP)
  |> drop(opening_tag())
  |> keep(ghp_children())
}

pub fn ghp_children() -> nibble.Parser(List(Grammar), a) {
  loop(
    [],
    fn(g) {
      one_of([
        closing_tag()
        |> nibble.replace(list.reverse(g))
        |> nibble.map(nibble.Break),
        eof()
        |> nibble.replace(list.reverse(g))
        |> nibble.map(nibble.Break),
        one_of([ghp(), elements()])
        |> nibble.map(fn(el) { nibble.Continue([el, ..g]) }),
      ])
    },
  )
}

pub fn full_block() -> nibble.Parser(Grammar, a) {
  succeed(curry2(Block))
  |> keep(take_while(fn(c) { c != ">" }))
  |> keep(ghp_children())
}
