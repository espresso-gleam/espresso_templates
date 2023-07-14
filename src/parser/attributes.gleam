import gleam/function.{curry2}
import nibble.{
  commit, drop, eof, keep, loop, one_of, string, succeed, take_while, whitespace,
}
import gleam/list

pub type Attribute {
  Attribute(name: String, value: String)
  GleamAttribute(name: String, value: String)
}

pub type Attributes =
  List(Attribute)

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
        gleam_attr()
        |> nibble.map(fn(attr) { nibble.Continue([attr, ..attrs]) }),
        nibble.map(
          attribute(),
          fn(attribute) { nibble.Continue([attribute, ..attrs]) },
        ),
      ])
    },
  )
}

pub fn gleam_attr() -> nibble.Parser(Attribute, a) {
  succeed(curry2(GleamAttribute))
  |> drop(whitespace())
  |> keep(take_while(fn(c) { c != "=" }))
  |> drop(string("={"))
  |> keep(take_while(fn(c) { c != "}" }))
  |> drop(string("}"))
  |> drop(whitespace())
}

/// Parses html attributes
/// class="stuff" -> Attribute("class", "stuff")
pub fn attribute() -> nibble.Parser(Attribute, a) {
  one_of([
    succeed(curry2(Attribute))
    |> drop(whitespace())
    |> keep(take_while(fn(c) { c != "=" && c != ">" }))
    |> drop(string("=\""))
    |> keep(take_while(fn(c) { c != "\"" }))
    |> drop(string("\""))
    |> drop(whitespace()),
    // Attributes without a value
    // i.e. "selected" "checked"
    succeed(curry2(Attribute))
    |> drop(whitespace())
    |> keep(take_while(fn(c) { c != " " && c != "=" && c != ">" }))
    |> keep(commit(""))
    |> drop(whitespace()),
  ])
}
