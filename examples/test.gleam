import espresso/html
import gleam/list

pub type Params {
  Params(items: List(String))
}

pub fn render(params: params) {
  html.t("html")
  |> html.c([
    html.t("head")
    |> html.c([
      html.t("title")
      |> html.c([html.txt("Espresso")]),
    ]),
  ])
  |> html.c([
    html.t("body")
    |> html.a("class", "w-full h-full")
    |> html.c([
      html.t("h1")
      |> html.a("class", "text-4xl")
      |> html.c([html.txt("This is a header")]),
    ])
    |> html.dyn({
      list.map(
        params.items,
        fn(item) {
          html.t("p")
          |> html.c([html.txt("Thing: ")])
          |> html.dyn({ item })
        },
      )
    }),
  ])
}
