import gleam/list
import nibble.{drop, eof, keep, loop, one_of, string, succeed, whitespace}
import parser/grammar.{GHP, Grammar}
import parser/elements.{elements}

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
  |> keep(children())
}

pub fn children() -> nibble.Parser(List(Grammar), a) {
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
