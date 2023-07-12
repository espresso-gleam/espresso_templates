import gleam/list

pub type Params {
  Params(items: List(String))
}

pub fn render(params: params) {
  c([
    t("html")
    |> c([
      t("head")
      |> c([
        t("title")
        |> c([txt("Espresso")]),
      ]),
    ])
    |> c([
      t("body")
      |> a("class", "w-full h-full")
      |> c([
        t("h1")
        |> a("class", "text-4xl")
        |> c([txt("This is a header")]),
      ])
      |> dyn(from({
        list.map(
          params.items,
          fn(item) {
            c([
              t("p")
              |> c([txt("Thing: ")])
              |> dyn(from({ item })),
            ])
          },
        )
      })),
    ]),
  ])
}
