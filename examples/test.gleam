import gleam/list

pub type Params {
  Params(items: List(String))
}

pub fn render(params: params) {
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
      t("h1")
      |> a("class", "text-4xl")
      |> c([txt("This is a header")]),
      txt("list.map(params.items, fn(item) {"),
      t("p")
      |> c([txt("Thing: txt(item)")]),
      txt("})"),
    ]),
  ])
}
