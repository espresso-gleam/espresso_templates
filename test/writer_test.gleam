import gleeunit
import writer
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn nested_void_element_test() {
  let result =
    writer.to_gleam(
      "<main>
        <img src=\"https://placekitten.com/200/300\" alt=\"kitten\" />
        <div class=\"thing\"></div>
      </main>",
    )

  should.equal(
    result,
    Ok(
      "import espresso/html.{a, c, t}

pub fn render(params: Params) {
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

pub fn block_loop_test() {
  let result =
    writer.to_gleam(
      "<main>
        <img src=\"https://placekitten.com/200/300\" alt=\"kitten\" />
        <% ..list.map(items, fn(item) { %>
          <p><% item %></p>
        <% }) %>
      </main>",
    )

  should.equal(
    result,
    Ok(
      "import espresso/html.{a, c, t}

pub fn render(params: Params) {
  t(\"main\")
  |> c([
    t(\"img\")
    |> a(\"src\", \"https://placekitten.com/200/300\")
    |> a(\"alt\", \"kitten\")
    |> c([]),
    ..list.map(
      items,
      fn(item) {
        t(\"p\")
        |> c([item])
      },
    )
  ])
}
",
    ),
  )
}

pub fn single_block_children_test() {
  let result =
    writer.to_gleam(
      "<div>
        <% list.map(params.items, fn(item) { %>
          <p>Thing: <% txt(item) %></p>
        <% }) %>
      </div>",
    )

  should.equal(
    result,
    Ok(
      "import espresso/html.{c, t}

pub fn render(params: Params) {
  t(\"div\")
  |> c(list.map(
    params.items,
    fn(item) {
      t(\"p\")
      |> c([txt(\"Thing:\"), txt(item)])
    },
  ))
}
",
    ),
  )
}

pub fn only_imports_tags_and_children_test() {
  let result = writer.to_gleam("<div></div>")

  should.equal(
    result,
    Ok(
      "import espresso/html.{c, t}

pub fn render(params: Params) {
  t(\"div\")
  |> c([])
}
",
    ),
  )
}

pub fn only_imports_tags_children_attr_test() {
  let result = writer.to_gleam("<div class=\"stuff\"></div>")

  should.equal(
    result,
    Ok(
      "import espresso/html.{a, c, t}

pub fn render(params: Params) {
  t(\"div\")
  |> a(\"class\", \"stuff\")
  |> c([])
}
",
    ),
  )
}

pub fn imports_all_test() {
  let result = writer.to_gleam("<div class=\"stuff\">Stuff here</div>")

  should.equal(
    result,
    Ok(
      "import espresso/html.{a, c, t, txt}

pub fn render(params: Params) {
  t(\"div\")
  |> a(\"class\", \"stuff\")
  |> c([txt(\"Stuff here\")])
}
",
    ),
  )
}
