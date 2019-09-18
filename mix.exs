defmodule PhoenixViewAssets.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_view_assets,
      version: "0.1.4",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Reio Piller"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/coingaming/phoenix_view_assets"},
      files: ~w(lib mix.exs README.md .formatter.exs),
      description:
        "Helps to manage view specific assets in phoenix project. Uses automatic code splitting to avoid over-fetching or downloading assets twice, if they are used in multiple views. Also supports phoenix live reload."
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
