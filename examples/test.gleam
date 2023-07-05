import espresso/html.{a, c, t, txt}
import gleam/list

pub type Params {
  Params(items: List(String))
}

pub fn render(params: Params) {
  t("html")
  |> c([
    t("head")
    |> c([
      t("title")
      |> c([txt("Espresso")]),
    ]),
    t("body")
    |> c([
      t("h1")
      |> c([txt("This is a header")]),
      ..list.map(
        params.items,
        fn(item) {
          t("p")
          |> c([txt("Thing: "), txt(item)])
        },
      )
    ]),
  ])
}
