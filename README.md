# PhoenixViewAssets

Helps to manage view specific assets in phoenix project. Uses automatic code splitting to avoid over-fetching or downloading assets twice, if they are used in multiple views. Also supports phoenix live reload.

## Installation

Add `phoenix_view_assets` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_view_assets, "~> 0.1"}
  ]
end
```

Use (or merge) `example_assets` for `assets/` in your project.

## Setup

1. Create module `MyApp.Assets`:
```elixir
defmodule MyAppWeb.Assets do
  use PhoenixViewAssets
end
```

2. Use `MyAppWeb.Assets` in your layout view to generate `scripts` and `styles` functions in compile time.
```elixir
defmodule MyApp.LayoutView do
  use MyAppWeb, :view
  use MyAppWeb.Assets
end
```

3. Use `styles` and `scripts` functions from `MyApp.Assets` to add assets to your layout:
```html
<head>
  ...
  <%= for path <- styles(@conn) do %>
    <link rel="stylesheet" href="#{path}" />
  <% end %>
</head>
<body>
  ...
  <%= for path <- scripts(@conn) do %>
    <script type="text/javascript" src="#{path}" />
  <% end %>
</body>
```
