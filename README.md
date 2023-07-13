# espresso_templatizer

Package that turns ghp formatted files into gleam code that can render in espresso.

## Quick start

```sh
npm install -g espresso_templatizer
# Watches **/*.ghp
espresso_templatizer watch
# Watches a specific path
espresso_templatizer watch --files="templates/**/*.ghp"
# Converts a specific file once
espresso_templatizer convert src/my_file.ghp
```

## Template Format

#### HTML

HTML blocks are denoted by >-> and <-<

For example:

```
import espresso/html

pub fn render() {
  >->
  <body>
    <h1 class="text-4xl text-white" id="header">This is a header</h1>
    <p>Our content goes here</p>
  </body>
  <-<
}
```

Gets turned into

```
import espresso/html

pub fn render() {
  html.t("body")
  |> html.c([
    html.t("h1")
    |> html.a("class", "text-4xl text-white")
    |> html.a("id", "header")
    |> html.c([html.txt("This is a header")]),
  ])
  |> html.c([
    html.t("p")
    |> html.c([html.txt("Our content goes here")]),
  ])
}
```

If you are inside an html block and want to go back to gleam you can use brackets to escape.

This will render the variable "things" into the `p` resulting in "Some things go here"

```
import espresso/html

pub fn render() {
  let things = "Some things "
  >->
  <body>
    <h1 class="text-4xl text-white" id="header">This is a header</h1>

    <p>{things} go here</p>
  </body>
  <-<
}
```

The html functions are designed to be passed to espresso's render function and sent as a response.

```
import espresso/router.{Router, get, to_routes}
import espresso/request.{Request}
import espresso/response.{render}
import espresso/html.{a, c, t, txt}
import espresso

let body =
  html.t("body")
  |> html.c([
    html.t("h1")
    |> html.a("class", "text-4xl text-white")
    |> html.a("id", "header")
    |> html.c([html.txt("This is a header")]),
  ])
  |> html.c([
    html.t("p")
    |> html.c([html.txt("Our content goes here")]),
  ])

let router =
  router.new()
  |> get("/", fn(_req: Request(BitString, assigns, session)) { render(body) })

espresso.start(router)
```

## Local development

- `npm install` to install dependencies
- `gleam run --target=javascript <commands>` to run the CLI
- `gleam test --target=javascript` to run tests
