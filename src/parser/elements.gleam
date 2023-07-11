import gleam/function.{curry3}
import gleam/list
import nibble.{
  backtrackable, commit, drop, eof, keep, loop, one_of, string, succeed,
  take_until, take_while, then, whitespace,
}
import parser/attributes.{attributes}
import parser/grammar.{GHP, GleamBlock, Grammar, HtmlElement, Text}
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

// fn gleam_block() -> nibble.Parser(Grammar, a) {
//   nibble.succeed(GHP)
//   |> nibble.drop(nibble.string("{"))
//   |> nibble.keep(balance_braces(1, ""))
//   // start with a count of 1 since we've consumed an open brace
//   // this will consume the closing brace
//   |> nibble.drop(nibble.whitespace())
//   |> nibble.inspect("block_as_text")
// }

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

fn text_outside() -> nibble.Parser(String, a) {
  nibble.take_while(fn(c) { c != "{" })
  |> nibble.drop(nibble.whitespace())
  |> nibble.inspect("text_outside")
}

fn text_inside() -> nibble.Parser(String, a) {
  nibble.take_while(fn(c) { c != "{" && c != "}" })
  |> nibble.drop(nibble.whitespace())
  |> nibble.inspect("text_inside")
}

fn balance_braces(count: Int, current: String) -> nibble.Parser(String, a) {
  nibble.one_of([
    nibble.string("}")
    |> nibble.then(fn(_c) {
      case count {
        1 ->
          // we've balanced the braces, so return the collected string
          current
          // |> parser.run()
          // |> result.unwrap("")
          |> nibble.succeed()
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
        0 -> nibble.succeed(current)
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
