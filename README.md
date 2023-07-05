# espresso_templatizer

Package that turns ghp formatted files into gleam code that can render in espresso.

## Quick start

```sh
npm install -g espresso_templatizer
espresso_templatizer watch src/**/*.ghp
# OR
espresso_templatizer convert src/my_file.ghp
```

## Template Format

#### Imports

Anything between `<%^ ^%>` gets placed at the top of the module, this is primarily used for imports.
For example:

```
<%^ import gleam/list ^%>
<%^
pub type Params { Params(items: List(String)) }
^%>
```

gets turned into

```
import gleam/list

pub type Params { Params(items: List(String)) }
```

#### Comments

HTML comments and anything inside of `<%% %%>` get turned into comments in the code. They aren't rendered
into the output HTML.

For example:

```
<%% Some things here %%>
<!-- More things here-->
```

Turns into

```
// Some things here
// More things here
```

#### Raw input

To do things like loops and referencing variables you can use `<% %>` to render whatever is inside.

For example:

```
<% ..list.map(params.items, fn(item) { %>
<p>Thing: <% txt(item) %></p>
<% }) %>
```

Gets turned into:

```
..list.map(
  params.items,
  fn(item) {
    t("p")
    |> c([txt("Thing: "), txt(item)])
  },
)
```

The main gotcha here is when dealing with lists if your are mapping a secondary element to use `..list.map` otherwise a compile error will be raised. If your child element only consists of your map you don't need the `..` in front of `list.map`.

#### HTML

Any html code in the template will get turned into a function pipeline that espresso can understand.

For example:

```
<body>
  <h1 class="text-4xl text-white" id="header">This is a header</h1>
  <p>Our content goes here</p>
</body>
```

Gets turned into

```
t("body")
|> c([
  t("h1")
  |> a("class", "text-4xl text-white")
  |> a("id", "header")
  |> c([txt("This is a header")]),
  t("p")
  |> c([txt("Our content goes here")]),
])
```

This is designed to be passed to espresso's render function.

```
import espresso/router.{Router, get, to_routes}
import espresso/request.{Request}
import espresso/response.{render}
import espresso/html.{a, c, t, txt}
import espresso

let body =
  t("body")
  |> c([
    t("h1")
    |> a("class", "text-4xl text-white")
    |> a("id", "header")
    |> c([txt("This is a header")]),
    t("p")
    |> c([txt("Our content goes here")]),
  ])

let router =
  router.new()
  |> get("/", fn(_req: Request(BitString, assigns, session)) { render(body) })

espresso.start(router)
```

## Local development

`npm install` to install dependencies
`gleam run --target=javascript <commands>` to run the CLI
`gleam test` to run tests
