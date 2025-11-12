defmodule TemporalEncoder.MixProject do
  use Mix.Project

  def project do
    [
      app: :temporal_encoder,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Encodes text messages into precise timestamps using morse code timing.
    Information is carried entirely in the temporal spacing between events,
    enabling covert communication through API call timing.
    """
  end

  defp package do
    [
      name: "temporal_encoder",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/yourusername/temporal_encoder"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
