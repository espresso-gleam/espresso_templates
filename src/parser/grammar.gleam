import parser/attributes.{Attributes}

pub type Grammar {
  GHP(children: List(Grammar))
  // "{|"
  GleamOpen(children: List(Grammar))
  // "|}"
  GleamClose
  // <tag_name attributes>children  
  HtmlElement(tag_name: String, attributes: Attributes, children: List(Grammar))
  // "blah blah blah"
  Text(String)
}
