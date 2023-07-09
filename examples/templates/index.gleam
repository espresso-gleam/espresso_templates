import espresso/html.{a, c, t, txt}

pub fn render(params: Params) {
  t("main")
  |> c([
    t("div")
    |> a("id", "notes")
    |> a("class", "mt-8 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4")
    |> c(list.map(params.notes, fn(note) { note.render(node) })),
  ])
}
