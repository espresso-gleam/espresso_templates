import parser/attributes.{Attributes}

pub type Grammar {
  Block(gleam: String, children: List(Grammar))
  GHP(children: List(Grammar))
  GleamBlock(text: Grammar)
  // <tag_name attributes>children  
  HtmlElement(tag_name: String, attributes: Attributes, children: List(Grammar))
  // "blah blah blah"
  Text(String)
}
