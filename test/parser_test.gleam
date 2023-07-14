import gleeunit
import gleeunit/should
import parser
import parser/grammar.{Block, GHP, HtmlElement, Text}
import parser/attributes.{Attribute}

pub fn main() {
  gleeunit.main()
}

pub fn full_example_with_single_attr_test() {
  let input =
    "import templates/notes/list as note
import schema/notes.{Note}

pub type Params {
  Params(notes: List(Note))
}

pub fn render(params: Params) {
  >->
  <form>
    <textarea required></textarea>
    
    <button type=\"submit\">
    </button>
  </form>
  <-<
}"

  let result = parser.parse(input)
  should.equal(
    result,
    Ok(Block(
      gleam: "import templates/notes/list as note
import schema/notes.{Note}

pub type Params {
  Params(notes: List(Note))
}

pub fn render(params: Params) {
  ",
      children: [
        GHP(children: [
          HtmlElement(
            tag_name: "form",
            attributes: [],
            children: [
              HtmlElement(
                tag_name: "textarea",
                attributes: [Attribute(name: "required", value: "")],
                children: [],
              ),
              HtmlElement(
                tag_name: "button",
                attributes: [Attribute(name: "type", value: "submit")],
                children: [],
              ),
            ],
          ),
        ]),
        Text("}"),
      ],
    )),
  )
}
