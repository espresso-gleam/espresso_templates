import gleeunit
import gleeunit/should
import espresso_templatizer.{
  Attribute, Comment, Element, Text, attribute, attributes, comment, document,
  element, text,
}
import nibble.{run}
import gleam/io

pub fn main() {
  gleeunit.main()
}

// ATTRIBUTES

pub fn attribute_parser_test() {
  let result = run("id=\"4\"", attribute())

  should.equal(result, Ok(Attribute(name: "id", value: "4")))
}

pub fn attributes_parser_test() {
  let result = run("id=\"4\" class=\"text-white flex\"", attributes())

  should.equal(
    result,
    Ok([Attribute("id", "4"), Attribute("class", "text-white flex")]),
  )
}

// COMMENTS

pub fn comment_parser_test() {
  let result =
    run(
      "
    <%% Multi line comments inside of this thing
    this one has
    more than one line.
    %%>
  ",
      comment(),
    )

  should.equal(
    result,
    Ok(Comment(
      "Multi line comments inside of this thing\n    this one has\n    more than one line.",
    )),
  )
}

// Elements
pub fn text_test() {
  let result = run("Stuff", text())

  should.equal(result, Ok(Text("Stuff")))
}

pub fn text_document_element_test() {
  let result = run("Stuff", document())

  should.equal(result, Ok(Text("Stuff")))
}

pub fn document_element_no_attributes_test() {
  let result = run("<div>Stuff</div>", document())

  should.equal(result, Ok(Element("div", [], [Text("Stuff")])))
}

pub fn document_element_nested_test() {
  let result =
    run(
      "<div>
    <p>Things go <b>here</b> but not
    over here</p>
  </div>",
      document(),
    )

  should.equal(
    result,
    Ok(Element(
      "div",
      [],
      [
        Element(
          "p",
          [],
          [
            Text("Things go "),
            Element("b", [], [Text("here")]),
            Text("but not\n    over here"),
          ],
        ),
      ],
    )),
  )
}
