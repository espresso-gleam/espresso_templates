import gleam/function.{curry3}
import gleam/list
import nibble.{
  Parser, backtrackable, commit, drop, eof, fail, grapheme, keep, many, one_of,
  string, succeed, take_if, take_if_and_while, take_until, take_while, then,
}
import gleam/string
import gleam/io

pub type Sad {
  Sad(String, String, String)
}

// pub fn parse_all_the_things_or_rollback(parser) {
//   parser
//   |> then(fn(c) {
//     io.debug(c)
//     one_of([
//       eof()
//       |> nibble.map(fn(_) { c }),
//       backtrackable(string("abc"))
//       |> drop(string("a"))
//       |> then(fn(sad) {
//         io.debug(sad)
//         fail("FAILED")
//       }),
//       succeed(fn(a) { a })
//       |> keep(take_if(fn(c) { c == "a" }, "a"))
//       |> take_until_string("abc"),
//     ])
//   })
// }

pub fn take_until_string(str: String) {
  succeed(fn(all_te_thing) { all_te_thing })
  |> keep(take_until(fn(c) { c == "a" }))
  |> then(fn(c) {
    backtrackable(one_of([
      eof()
      |> nibble.map(fn(_) { c }),
      string("abc")
      |> then(fn(sad) {
        io.debug(sad)
        commit(c)
      }),
      string("a")
      |> then(fn(_) { commit(c <> "a") }),
    ]))
  })
  |> nibble.map(fn(c) {
    io.debug("SAD")
    c
  })
  // let graphemes = string.to_graphemes(str)

  // case graphemes {
  //   [] -> succeed("")
  //   [head, ..tail] ->
  //     list.fold(
  //       tail,
  //       succeed(
  //         grapheme("s")
  //         |> keep(commit("")),
  //       ),
  //       fn(parser, l) { keep(parser, grapheme(l)) },
  //     )
  // }
}
