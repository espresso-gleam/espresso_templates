import nibble
import parser/elements.{full_block}

pub fn parse(code: String) {
  nibble.run(code, full_block())
}
