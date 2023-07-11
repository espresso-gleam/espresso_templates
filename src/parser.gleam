import nibble.{
  commit, drop, eof, keep, loop, one_of, string, succeed, take_while, then,
  whitespace,
}
import gleam/list
import gleam/string
import parser/grammar.{GHP, Grammar, Text}
import parser/elements.{elements}
// pub fn grammar() -> nibble.Parser(Grammar, a) {
//   one_of([ghp(), elements()])
// }

// pub fn grammar_loop() -> nibble.Parser(List(Grammar), a) {
//   loop(
//     [],
//     fn(g) {
//       one_of([
//         eof()
//         |> nibble.replace(list.reverse(g))
//         |> nibble.map(nibble.Break),
//         grammar()
//         |> nibble.map(fn(el) { nibble.Continue([el, ..g]) }),
//       ])
//     },
//   )
// }

// pub fn ghp() -> nibble.Parser(Grammar, a) {
//   succeed(GHP)
//   |> drop(whitespace())
//   |> drop(string(">->"))
//   |> drop(whitespace())
//   |> keep(grammar_loop())
//   |> drop(whitespace())
//   |> drop(ghp_close())
// }

// pub fn ghp_close() -> nibble.Parser(Grammar, a) {
//   succeed(GHPClose)
//   |> drop(whitespace())
//   |> drop(string("<-<"))
//   |> drop(whitespace())
// }

// pub fn text() -> nibble.Parser(Grammar, a) {
//   succeed(Text)
//   |> drop(whitespace())
//   |> keep(
//     // take while not a 
//     // <-<
//     // <html>
//     // {| |}
//     take_while(fn(c) { c != "<" })
//     |> then(fn(text) {
//       text
//       |> string.trim()
//       |> commit()
//     }),
//   )
//   |> drop(whitespace())
// }
// pub fn parse(input: String) -> Result(List(Grammar), List(nibble.DeadEnd(a))) {
//   nibble.run(input, grammar_loop())
// }
