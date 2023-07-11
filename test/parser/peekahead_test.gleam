import gleeunit
import gleeunit/should
import nibble.{run}
import parser/grammar.{GHP, GleamBlock, HtmlElement, Text}
import parser/ghp.{children, closing_tag, ghp, opening_tag}
import parser/attributes.{Attribute}
import parser/peekahead.{take_until_string}

pub fn main() {
  gleeunit.main()
}

pub fn parses_until_string_test() {
  let result =
    nibble.run("bnassddaaaaanasakljdflkasjgzoddasjh", take_until_string("zod"))

  should.equal(result, Ok("bn"))
}
