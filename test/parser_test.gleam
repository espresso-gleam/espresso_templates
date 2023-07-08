import gleeunit
import gleeunit/should
import parser.{
  Attribute, Block, ClosingScope, Comment, DocTypeDeclaration, Element, Import,
  OpeningScope, Text, attribute, attributes, comment, document, documents,
  element, html_comment, opening_scope, quoted_block, text,
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

pub fn mixed_attributes_parser_test() {
  let result =
    run(
      "selected data-test-id=\"12\" checked id=\"4\" class=\"text-white flex\"",
      attributes(),
    )

  should.equal(
    result,
    Ok([
      Attribute(name: "selected", value: ""),
      Attribute(name: "data-test-id", value: "12"),
      Attribute(name: "checked", value: ""),
      Attribute(name: "id", value: "4"),
      Attribute(name: "class", value: "text-white flex"),
    ]),
  )
}

pub fn void_element_mixed_attributes_parser_test() {
  let result = run("<input type=\"text\" required>", document())

  should.equal(
    result,
    Ok(Element(
      "input",
      [Attribute("type", "text"), Attribute("required", "")],
      [],
    )),
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

pub fn html_comment_test() {
  let result = run("<!-- Write your comments here -->", html_comment())

  should.equal(result, Ok(Comment("Write your comments here")))
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

pub fn self_closing_element_without_attrs_test() {
  let result = run("<br/>", document())
  should.equal(result, Ok(Element("br", [], [])))
}

pub fn self_closing_element_with_attrs_test() {
  let result =
    run(
      "<link rel=\"stylesheet\" href=\"https://stuff.thing.app.css\"",
      element(),
    )

  should.equal(
    result,
    Ok(Element(
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
    Ok(Element(
      "head",
      [],
      [
        Element("meta", [Attribute("lang", "en")], []),
        Element(
          "link",
          [
            Attribute("rel", "stylesheet"),
            Attribute("href", "https://stuff.thing/app.css"),
          ],
          [],
        ),
        Element("script", [Attribute("src", "app.js")], []),
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
    Ok(Element(
      "main",
      [],
      [
        Element(
          "img",
          [
            Attribute("src", "https://placekitten.com/200/300"),
            Attribute("alt", "kitten"),
          ],
          [],
        ),
        Element("div", [Attribute("class", "thing")], []),
      ],
    )),
  )
}

pub fn document_element_nested_test() {
  let result =
    run(
      "
      <div>Top level thing here</div>

      <div>
      <%^ import gleam/list ^%>
      <%% Commented thing %%>
    <p>Things go <b>here</b> but not
    over here</p>
  </div>",
      documents(),
    )

  should.equal(
    result,
    Ok([
      Element("div", [], [Text("Top level thing here")]),
      Element(
        "div",
        [],
        [
          Import("import gleam/list"),
          Comment("Commented thing"),
          Element(
            "p",
            [],
            [
              Text("Things go"),
              Element("b", [], [Text("here")]),
              Text("but not\n    over here"),
            ],
          ),
        ],
      ),
    ]),
  )
}

pub fn document_header_test() {
  let result =
    run(
      "
      <!DOCTYPE html>
<html lang=\"en\">
  <!-- This is the head -->
  <head></head>
  <body>
    <h1>Test</h1>
    <p>Test</p>
  </body>
</html>",
      documents(),
    )

  should.equal(
    result,
    Ok([
      DocTypeDeclaration,
      Element(
        "html",
        [Attribute("lang", "en")],
        [
          Comment("This is the head"),
          Element("head", [], []),
          Element(
            "body",
            [],
            [
              Element("h1", [], [Text("Test")]),
              Element("p", [], [Text("Test")]),
            ],
          ),
        ],
      ),
    ]),
  )
}

pub fn quoted_block_test() {
  let result = run("<% list.map(items, fn(item) { %>", quoted_block())
  should.equal(result, Ok(Block("list.map(items, fn(item) {")))
}

pub fn quoted_block_nested_test() {
  let result =
    run(
      "
  <body>
    <h1>Test</h1>
    <% list.map(items, fn(item) { %>
      <p><% item %></p>
    <% }) %>
  </body>
  ",
      document(),
    )
  should.equal(
    result,
    Ok(Element(
      tag_name: "body",
      attributes: [],
      children: [
        Element(tag_name: "h1", attributes: [], children: [Text("Test")]),
        OpeningScope(
          header: "list.map(items, fn(item) {",
          children: [
            Element(tag_name: "p", attributes: [], children: [Block("item")]),
            ClosingScope("})"),
          ],
        ),
      ],
    )),
  )
}

pub fn scoped_block_parser_test() {
  let result =
    run(
      "
  <% list.map(params.items, fn(item) { %>
    <p>Thing: <% txt(item) %></p>
  <% }) %>
  ",
      opening_scope(),
    )

  should.equal(
    result,
    Ok(OpeningScope(
      header: "list.map(params.items, fn(item) {",
      children: [
        Element(
          tag_name: "p",
          attributes: [],
          children: [Text("Thing:"), Block("txt(item)")],
        ),
        ClosingScope("})"),
      ],
    )),
  )
}
