import espresso/html.{a, c, t, txt}

pub fn render(params: Params) {
  t("div")
  |> c(list.map(
    params.items,
    fn(item) {
      t("p")
      |> c([txt("Thing:"), txt(item)])
    },
  ))
}
