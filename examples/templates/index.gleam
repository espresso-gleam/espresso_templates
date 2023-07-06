import espresso/html.{a, c, t, txt}

pub fn render(params: Params) {
  t("main")
  |> c([
    t("img")
    |> a("src", "https://placekitten.com/200/300")
    |> a("alt", "kitten")
    |> c([]),
    t("body")
    |> a("class", "w-full h-full")
    |> c([
      t("h1")
      |> a("class", "text-4xl")
      |> c([txt("This is a header")]),
      ..list.map(
        params.items,
        fn(item) {
          t("p")
          |> c([txt("Thing:"), txt(item)])
        },
      )
    ]),
  ])
}
