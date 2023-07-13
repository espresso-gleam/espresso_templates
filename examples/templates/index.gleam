pub fn main() {
  html.t("main")
  |> html.c([
    html.t("div")
    |> html.a("id", "notes")
    |> html.a(
      "class",
      "mt-8 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4",
    )
    |> html.dyn({ list.map(params.notes, fn(note) { note.render(node) }) }),
  ])
}
