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
    |> a("class", "w-full h-full")
    |> c([
      t("button")
      |> a("type", "button")
      |> a("hx-vals", "{id:" <> params.note.id <> "}")
      |> c([txt("Delete")]),
    ]),
  ])
}
