defmodule AlexaVerifier.Mixfile do
  use Mix.Project

  def project do
    [app: :alexa_verifier,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "A Plug to verify signatures for Amazon Alexa requests",
     package: package,
     deps: deps()]
  end

  def package do
    [
      maintainers: ["Colin Harris"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/col/alexa_verifier"}
    ]
  end

  def application do
    [applications: [:logger, :porcelain, :httpoison]]
  end

  defp deps do
    [{:porcelain, "~> 2.0"},
     {:httpoison, "~> 0.9.0"},
     {:plug, "~> 1.1.6"}]
  end
end
