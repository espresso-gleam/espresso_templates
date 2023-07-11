import gleeunit
import gleeunit/should
import nibble.{run}
import parser/grammar.{GHP, HtmlElement, Text}
import parser/attributes.{Attribute}

// import parser.{ghp}

pub fn main() {
  gleeunit.main()
}
// pub fn ghp_no_child_test() {
//   let result =
//     run(
//       ">->
// <-<  
// ",
//       ghp(),
//     )

//   should.equal(result, Ok(GHP([])))
// }

// pub fn ghp_text_child_test() {
//   let result =
//     run(
//       ">->
// Inner things
// go here.
// <-<
// ",
//       ghp(),
//     )

//   should.equal(result, Ok(GHP(children: [Text("Inner things\ngo here.")])))
// }

// pub fn ghp_void_element_child_test() {
//   let result =
//     run(
//       ">->
// <input type=\"text\" />
// <-<  
// ",
//       ghp(),
//     )

//   should.equal(
//     result,
//     Ok(GHP([
//       HtmlElement(
//         tag_name: "input",
//         attributes: [Attribute(name: "type", value: "text")],
//         children: [],
//       ),
//     ])),
//   )
// }

// pub fn ghp_single_element_child_test() {
//   let result =
//     run(
//       ">->
// <div></div>
// <-<  
// ",
//       ghp(),
//     )

//   should.equal(result, Ok(GHP([])))
// }
