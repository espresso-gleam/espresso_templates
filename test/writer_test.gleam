import gleeunit
import writer
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn nested_void_element_test_() {
  let result =
    writer.to_gleam(
      "pub fn main() {
  >->
    <main>
      <img src=\"https://placekitten.com/200/300\" alt=\"kitten\" />
      <div class=\"thing\"></div>
    </main>
  <-<
}",
    )

  should.equal(
    result,
    Ok(
      "pub fn main() {
  t(\"main\")
  |> c([
    t(\"img\")
    |> a(\"src\", \"https://placekitten.com/200/300\")
    |> a(\"alt\", \"kitten\")
    |> c([]),
    t(\"div\")
    |> a(\"class\", \"thing\")
    |> c([]),
  ])
}
",
    ),
  )
}

pub fn no_renders_test_() {
  let result =
    writer.to_gleam(
      "import gleam/list
 pub fn main() {
   list.map([1,2,3], fn(x) { 
     x 
   })
 }",
    )

  should.equal(
    result,
    Ok(
      "import gleam/list

pub fn main() {
  list.map([1, 2, 3], fn(x) { x })
}
",
    ),
  )
}

pub fn nested_render_test() {
  let result =
    writer.to_gleam(
      "pub fn main() {
  >->
    <main>
      <img src=\"https://placekitten.com/200/300\" alt=\"kitten\" />
      <h3>{title()}{title()}</h3>
      <ul>
        {
          list.map(things, fn (thing) {
            let name = get_list_name(thing)
            >->
            <li>{name}</li>
            <-<
          }
        }
      </ul>
    </main>
  <-<
}",
    )

  should.equal(
    result,
    Ok(
      "pub fn main() {
  t(\"main\")
  |> c([
    t(\"img\")
    |> a(\"src\", \"https://placekitten.com/200/300\")
    |> a(\"alt\", \"kitten\")
    |> c([]),
    t(\"div\")
    |> a(\"class\", \"thing\")
    |> c([]),
  ])
}
",
    ),
  )
}
