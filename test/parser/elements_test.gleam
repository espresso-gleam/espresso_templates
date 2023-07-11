import gleeunit
import gleeunit/should
import nibble.{run}
import parser/grammar.{HtmlElement}
import parser/attributes.{Attribute}
import parser/elements.{element, void_element}

pub fn main() {
  gleeunit.main()
}

// VOID ELEMENT
pub fn void_element_test() {
  let result = run("<br />", void_element())

  should.equal(result, Ok(HtmlElement("br", [], [])))
}

pub fn void_element_with_attrs_test() {
  let result = run("<input type=\"test\" />", void_element())

  should.equal(
    result,
    Ok(HtmlElement(
      tag_name: "input",
      attributes: [Attribute(name: "type", value: "test")],
      children: [],
    )),
  )
}

pub fn void_element_with_single_attrs_test() {
  let result = run("<input type=\"test\" required />", void_element())

  should.equal(
    result,
    Ok(HtmlElement(
      tag_name: "input",
      attributes: [
        Attribute(name: "type", value: "test"),
        Attribute(name: "required", value: ""),
      ],
      children: [],
    )),
  )
}

pub fn void_element_no_closing_slash_test() {
  let result = run("<input>", void_element())

  should.equal(
    result,
    Ok(HtmlElement(tag_name: "input", attributes: [], children: [])),
  )
}

// ELEMENT
pub fn element_no_children_test() {
  let result = run("<div></div>", element())

  should.equal(
    result,
    Ok(HtmlElement(tag_name: "div", attributes: [], children: [])),
  )
}

pub fn element_no_children_with_attributes_test() {
  let result = run("<div id=\"thing\" class=\"flex\"></div>", element())

  should.equal(
    result,
    Ok(HtmlElement(
      tag_name: "div",
      attributes: [
        Attribute(name: "id", value: "thing"),
        Attribute(name: "class", value: "flex"),
      ],
      children: [],
    )),
  )
}

pub fn element_with_children_test() {
  let result = run("<div><span></span></div>", element())

  should.equal(
    result,
    Ok(HtmlElement(
      tag_name: "div",
      attributes: [],
      children: [HtmlElement(tag_name: "span", attributes: [], children: [])],
    )),
  )
}

pub fn element_with_children_with_attributes_test() {
  let result =
    run(
      "<div id=\"header\"><span class=\"text-black\"></span></div>",
      element(),
    )

  should.equal(
    result,
    Ok(HtmlElement(
      tag_name: "div",
      attributes: [Attribute(name: "id", value: "header")],
      children: [
        HtmlElement(
          tag_name: "span",
          attributes: [Attribute(name: "class", value: "text-black")],
          children: [],
        ),
      ],
    )),
  )
}
