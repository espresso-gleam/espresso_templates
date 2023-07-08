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
      "import espresso/html.{a, c, t, txt}\n\npub fn render(params: Params) {\n  t(\"main\")\n  |> c([\n    t(\"img\")\n    |> a(\"src\", \"https://placekitten.com/200/300\")\n    |> a(\"alt\", \"kitten\")\n    |> c([]),\n    t(\"div\")\n    |> a(\"class\", \"thing\")\n    |> c([]),\n  ])\n}\n",
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
      "import espresso/html.{a, c, t, txt}

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
      "import espresso/html.{a, c, t, txt}

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
