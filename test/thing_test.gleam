import gleeunit
import gleeunit/should
import nibble.{run}
import gleam/io
import gleam/list

pub fn main() {
  gleeunit.main()
}

type Token {
  Text(String)
  Block(List(Token))
  StringBlock(String)
  Arrow(List(Token))
}

// fn block() -> nibble.Parser(Token, a) {
//   nibble.backtrackable(
//     nibble.succeed(Block)
//     |> nibble.drop(nibble.string("{"))
//     |> nibble.keep(contents())
//     |> nibble.drop(nibble.whitespace()),
//   )
// }

// fn contents() -> nibble.Parser(List(Token), a) {
//   nibble.loop(
//     [],
//     fn(content) {
//       nibble.one_of([
//         nibble.string("}")
//         |> nibble.replace(list.reverse(content))
//         |> nibble.map(nibble.Break),
//         block()
//         |> nibble.map(fn(block) { nibble.Continue([block, ..content]) }),
//         text_inside()
//         |> nibble.map(Text)
//         |> nibble.map(fn(text) { nibble.Continue([text, ..content]) }),
//       ])
//     },
//   )
// }

// fn main_parser() -> nibble.Parser(List(Token), a) {
//   nibble.loop(
//     [],
//     fn(content) {
//       nibble.one_of([
//         nibble.eof()
//         |> nibble.replace(list.reverse(content))
//         |> nibble.map(nibble.Break),
//         block()
//         |> nibble.map(fn(block) { nibble.Continue([block, ..content]) }),
//         text_outside("}")
//         |> nibble.map(Text)
//         |> nibble.map(fn(text) { nibble.Continue([text, ..content]) }),
//       ])
//     },
//   )
//   |> nibble.inspect("main_parser")
// }

// fn block_as_text() -> nibble.Parser(Token, a) {
//   nibble.succeed(StringBlock)
//   |> nibble.drop(nibble.string("{"))
//   |> nibble.keep(balance_braces(1, ""))
//   // start with a count of 1 since we've consumed an open brace
//   // this will consume the closing brace
//   |> nibble.drop(nibble.whitespace())
//   |> nibble.inspect("block_as_text")
// }

// fn balance_braces(count: Int, current: String) -> nibble.Parser(String, a) {
//   nibble.one_of([
//     nibble.string("}")
//     |> nibble.then(fn(_c) {
//       case count {
//         1 ->
//           // we've balanced the braces, so return the collected string
//           nibble.succeed(current)
//         _ ->
//           // still more closing braces to find
//           balance_braces(count - 1, current <> "}")
//       }
//     }),
//     nibble.string("{")
//     |> nibble.then(fn(_c) {
//       // we've found an opening brace, increase the count
//       balance_braces(count + 1, current <> "{")
//     }),
//     nibble.any()
//     |> nibble.then(fn(c) {
//       // add the character to the string and continue
//       balance_braces(count, current <> c)
//     }),
//     nibble.eof()
//     |> nibble.then(fn(_) {
//       case count {
//         0 -> nibble.succeed(current)
//         _ -> nibble.fail("Unbalanced braces")
//       }
//     }),
//   ])
// }

fn text_outside(until_char: String) -> nibble.Parser(String, a) {
  nibble.take_while(fn(c) { c != until_char })
  |> nibble.drop(nibble.whitespace())
}

// fn text_inside1() -> nibble.Parser(String, a) {
//   nibble.take_while(fn(c) { c != "{" && c != "}" })
//   |> nibble.drop(nibble.whitespace())
//   |> nibble.inspect("text_inside")
// }

fn text_inside() -> nibble.Parser(String, a) {
  nibble.take_while(fn(c) { c != "<" && c != ">" })
  |> nibble.drop(nibble.whitespace())
}

fn maybe_append_text(tokens: List(Token), str: String) {
  case tokens {
    [head, ..tail] ->
      case head {
        Text(prev) -> [Text(prev <> str), ..tail]
        _ -> [Text(str), ..tokens]
      }
    _ -> [Text(str), ..tokens]
  }
}

fn inside_arrows() {
  nibble.loop(
    [],
    fn(content) {
      nibble.one_of([
        nibble.backtrackable(nibble.string("<-<"))
        |> nibble.replace(list.reverse(content))
        |> nibble.map(nibble.Break),
        nibble.string("<")
        |> nibble.map(fn(_) { nibble.Continue(maybe_append_text(content, "<")) }),
        text_outside("<")
        |> nibble.map(fn(text) {
          nibble.Continue(maybe_append_text(content, text))
        }),
      ])
    },
  )
  // |> nibble.inspect("inside_arrow")
}

fn arrow() -> nibble.Parser(Token, a) {
  nibble.backtrackable(
    nibble.succeed(Arrow)
    |> nibble.drop(nibble.string(">->"))
    |> nibble.keep(inside_arrows()),
  )
  // |> nibble.inspect("arrow"),
}

fn arrow_parser() -> nibble.Parser(List(Token), a) {
  nibble.loop(
    [],
    fn(tokens) {
      nibble.one_of([
        nibble.eof()
        |> nibble.replace(list.reverse(tokens))
        |> nibble.map(nibble.Break),
        arrow()
        |> nibble.map(fn(block) { nibble.Continue([block, ..tokens]) }),
        nibble.string(">")
        |> nibble.map(fn(_block) {
          let x = maybe_append_text(tokens, ">")
          nibble.Continue(x)
        }),
        text_outside(">")
        |> nibble.map(fn(text) {
          nibble.Continue(maybe_append_text(tokens, text))
        }),
      ])
    },
  )
  // |> nibble.inspect("arrow_parser")
}

pub fn bs_test() {
  let input = "if (a > 3) { >-><div id=\"main\"></div><-< arrow }"
  let result = run(input, arrow_parser())
  io.println("input:")
  io.debug(input)
  io.println("result:")
  io.debug(result)

  True
}
