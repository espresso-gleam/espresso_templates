import gleeunit
import gleeunit/should
import nibble.{run}
import parser/grammar.{GHP, GleamBlock, HtmlElement, Text}
import parser/ghp.{children, closing_tag, ghp, opening_tag}
import parser/attributes.{Attribute}

pub fn main() {
  gleeunit.main()
}

// >->
pub fn opening_tag_test() {
  let result = run("     >->     ", opening_tag())
  should.equal(result, Ok(Nil))
}

// <-<
pub fn closing_tag_test() {
  let result = run("     <-<      ", closing_tag())
  should.equal(result, Ok(Nil))
}

// Children

pub fn empty_children_test() {
  let result = run("", children())
  should.equal(result, Ok([]))
}

// Inner block

pub fn empty_inner_block_test() {
  let result = run("     >->     <-<      ", ghp())
  should.equal(result, Ok(GHP([])))
}

pub fn html_inner_block_test() {
  let result =
    run(
      ">->
<div class=\"bananas\">Test</div>
<div id=\"thing\"></div>
<-<",
      ghp(),
    )
  should.equal(
    result,
    Ok(GHP(children: [
      HtmlElement(
        tag_name: "div",
        attributes: [Attribute(name: "class", value: "bananas")],
        children: [Text("Test")],
      ),
      HtmlElement(
        tag_name: "div",
        attributes: [Attribute(name: "id", value: "thing")],
        children: [],
      ),
    ])),
  )
}

pub fn html_with_gleam_block_test() {
  let result =
    run(
      ">->
<div class=\"bananas\">{\"shoe\"}</div>
<-<",
      ghp(),
    )
  should.equal(
    result,
    Ok(GHP(children: [
      HtmlElement(
        tag_name: "div",
        attributes: [Attribute(name: "class", value: "bananas")],
        children: [GleamBlock("\"shoe\"")],
      ),
    ])),
  )
}

pub fn html_with_gleam_block_with_nested_braces_test() {
  let result =
    run(
      ">->
<div class=\"bananas\">{
  let banana = fn (shoe) {
    shoe
  }
  banana(\"lol\")
  >->
  <div class=\"red\">RED</div>
  <-<
}<p>lol</p></div>
<-<",
      ghp(),
    )
  should.equal(
    result,
    Ok(GHP(children: [
      HtmlElement(
        tag_name: "div",
        attributes: [Attribute(name: "class", value: "bananas")],
        children: [GleamBlock("\"shoe\"")],
      ),
    ])),
  )
}
