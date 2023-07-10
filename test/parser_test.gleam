import gleeunit
import gleeunit/should
import parser.{
  Attribute, Gleam, HtmlElement, Text, attribute, attributes, element, text,
  tokens, void_element,
}
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

// HtmlElements
pub fn text_test() {
  let result = run("Stuff", text())

  should.equal(result, Ok(Text("Stuff")))
}

pub fn text_document_element_test() {
  let result = run("Stuff", text())

  should.equal(result, Ok(Text("Stuff")))
}

pub fn document_element_no_attributes_test() {
  let result = run("<div>Stuff</div>", element())

  should.equal(result, Ok(HtmlElement("div", [], [Text("Stuff")])))
}

pub fn self_closing_element_without_attrs_test() {
  let result = run("<br/>", void_element())
  should.equal(result, Ok(HtmlElement("br", [], [])))
}

pub fn self_closing_element_with_attrs_test() {
  let result =
    run(
      "<link rel=\"stylesheet\" href=\"https://stuff.thing.app.css\"",
      element(),
    )

  should.equal(
    result,
    Ok(HtmlElement(
      "link",
      [
        Attribute("rel", "stylesheet"),
        Attribute("href", "https://stuff.thing.app.css"),
      ],
      [],
    )),
  )
}

pub fn nested_self_closing_element_test() {
  let result =
    run(
      "<head>
         <meta lang=\"en\">
         <link rel=\"stylesheet\" href=\"https://stuff.thing/app.css\" />
         <script src=\"app.js\"></script>
       </head>",
      element(),
    )

  should.equal(
    result,
    Ok(HtmlElement(
      "head",
      [],
      [
        HtmlElement("meta", [Attribute("lang", "en")], []),
        HtmlElement(
          "link",
          [
            Attribute("rel", "stylesheet"),
            Attribute("href", "https://stuff.thing/app.css"),
          ],
          [],
        ),
        HtmlElement("script", [Attribute("src", "app.js")], []),
      ],
    )),
  )
}

pub fn self_closing_siblings_test() {
  let result =
    run(
      "<main>
         <img src=\"https://placekitten.com/200/300\" alt=\"kitten\" />
         <div class=\"thing\"></div>
       </main>",
      element(),
    )

  should.equal(
    result,
    Ok(HtmlElement(
      "main",
      [],
      [
        HtmlElement(
          "img",
          [
            Attribute("src", "https://placekitten.com/200/300"),
            Attribute("alt", "kitten"),
          ],
          [],
        ),
        HtmlElement("div", [Attribute("class", "thing")], []),
      ],
    )),
  )
}

// Gleam code

pub fn gleam_code_test() {
  let result =
    run(
      "import espresso/html.{a, c, t, txt}
import gleam/list

pub type Params {
  Params(items: List(String))
}

pub fn notes(params: Params) {
  >->
  <ul>
    list.map(params.items, fn(item) {
      note(item)
    }
  </ul>
  <-<
}

pub fn note(content: String) {
  >->
  <div>{item}</div>
  <-<
}
",
      tokens(),
    )

  should.equal(
    result,
    Ok([
      Gleam(
        "import espresso/html.{a, c, t, txt}\nimport gleam/list\n\npub type Params {\n  Params(items: List(String))\n}\n\npub fn notes(params: Params) {\n  ",
      ),
      HtmlElement(
        "ul",
        [],
        [Text("list.map(params.items, fn(item) {\n      note(item)\n    }")],
      ),
      Gleam("}\n\npub fn note(content: String) {\n  "),
      HtmlElement("div", [], [Text("{item}")]),
      Gleam("}\n"),
    ]),
  )
}
