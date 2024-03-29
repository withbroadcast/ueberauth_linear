defmodule UeberauthLinear.MixProject do
  use Mix.Project

  @version "0.2.0"
  @url "https://github.com/withbroadcast/ueberauth_linear"

  def project do
    [
      app: :ueberauth_linear,
      version: @version,
      name: "Ueberauth Linear Strategy",
      package: package(),
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod,
      source_url: @url,
      homepage_url: @url,
      description: description(),
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:logger, :ueberauth, :oauth2]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oauth2, "~> 2.0"},
      {:ueberauth, "~> 0.7"},
      {:jason, "~> 1.0"},

      # dev/test dependencies
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, "~> 0.18", only: :dev},
      {:credo, "~> 0.8", only: [:dev, :test]}
    ]
  end

  defp docs do
    [extras: ["README.md"]]
  end

  defp description do
    "An Uberauth strategy for Linear authentication."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Connor Jacobsen"],
      licenses: ["MIT"],
      links: %{GitHub: @url}
    ]
  end
end
