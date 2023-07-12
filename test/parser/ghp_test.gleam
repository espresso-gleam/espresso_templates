import gleeunit
import gleeunit/should
import nibble.{run}
import parser/grammar.{Block, GHP, GleamBlock, HtmlElement, Text}
import parser/elements.{closing_tag, full_block, ghp, ghp_children, opening_tag}
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
  let result = run("", ghp_children())
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
        children: [GleamBlock(text: Block(gleam: "\"shoe\"", children: []))],
      ),
    ])),
  )
}

pub fn html_with_gleam_block_with_nested_braces_test() {
  let result =
    run(
      "
import gleam/list      

pub fn main() {
  let stuff = \"a stuff\"
  
  >->
  <div class=\"bananas\">
    <h1>{stuff}</h1>
    {
      let banana = fn (shoe) {
        shoe
      }
      banana(\"lol\")
      
      >->
      <div class=\"red\">RED</div>
      <-<
    }
  </div>
  <-<
}",
      full_block(),
    )
  should.equal(
    result,
    Ok(Block(
      gleam: "\nimport gleam/list      \n\npub fn main() {\n  let stuff = \"a stuff\"\n  \n  ",
      children: [
        GHP(children: [
          HtmlElement(
            tag_name: "div",
            attributes: [Attribute(name: "class", value: "bananas")],
            children: [
              HtmlElement(
                tag_name: "h1",
                attributes: [],
                children: [
                  GleamBlock(text: Block(gleam: "stuff", children: [])),
                ],
              ),
              GleamBlock(text: Block(
                gleam: "\n      let banana = fn (shoe) {\n        shoe\n      }\n      banana(\"lol\")\n      \n      ",
                children: [
                  GHP(children: [
                    HtmlElement(
                      tag_name: "div",
                      attributes: [Attribute(name: "class", value: "red")],
                      children: [Text("RED")],
                    ),
                  ]),
                ],
              )),
            ],
          ),
        ]),
        Text("}"),
      ],
    )),
  )
}
