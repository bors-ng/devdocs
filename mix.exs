defmodule Devdocs.Mixfile do
  use Mix.Project

  def project do
    [app: :devdocs,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [mod: {DevDocs, []},
     extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_link_header, "~> 0.0.5"},
      {:poison, "~> 5.0"},
      {:httpoison, "~> 1.8.0"},
      {:joken, "~> 2.3"},
      {:jose, "~> 1.8"},
      {:etoml, [git: "git://github.com/kalta/etoml.git"]},
      {:ex_doc, "~> 0.14"},
    ]
  end
end
