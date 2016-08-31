defmodule DefUnit.Mixfile do
  use Mix.Project

  def project do
    [app: :defunit,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps(),
     package: package()]
  end
  
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ex_doc, "~> 0.12", only: :dev}]
  end
  
  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE*"],
      maintainers: ["Robin Hilliard"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/robinhilliard/defunit.git"},
      description: """
      DefUnit provides a pair of macros that allow you to quickly create a module that
      defines a set of core units (SI, FPS, currency, whatever) for its users to work with.
      The macros create documentation attributes, conversion operators and type specs that allow
      Dialyzer to detect most incompatible assignments at compile time.
      """
    ]
  end
end
