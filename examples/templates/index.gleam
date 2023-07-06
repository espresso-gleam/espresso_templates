import espresso/html.{a, c, t, txt}

pub fn render(params: Params) {
  t("main")
  |> c([
    t("img")
    |> a("src", "https://placekitten.com/200/300")
    |> a("alt", "kitten")
    |> c([]),
    t("div")
    |> a("class", "thing")
    |> c([]),
  ])
}
