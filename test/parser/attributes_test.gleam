import gleeunit
import gleeunit/should
import parser/attributes.{Attribute, GleamAttribute, attribute, attributes}
import nibble.{run}

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

pub fn single_attribute_parser_test() {
  let result = run("name=\"username\" required", attributes())

  should.equal(
    result,
    Ok([Attribute("name", "username"), Attribute("required", "")]),
  )
}

pub fn dynamic_attributes_test() {
  let result =
    run(
      "id=\"4\" class=\"text-white flex\" href={\"/thing/\" <> id}",
      attributes(),
    )

  should.equal(
    result,
    Ok([
      Attribute("id", "4"),
      Attribute("class", "text-white flex"),
      GleamAttribute("href", "\"/thing/\" <> id"),
    ]),
  )
}
