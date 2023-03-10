defmodule EctoViewMigrations.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_view_migrations,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Ecto ViewMigrations",
      source_url: "https://github.com/mveytsman/ecto_view_migrations",
      description: "View migrations for Ecto!",
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mveytsman/ecto_view_migrations"}
    ]
  end

  defp docs do
    []
  end
end
