defmodule YyScaffold.Mixfile do
  use Mix.Project

  # Version control should also be maintained at
  # lib/mix_scaffold/config.ex
  def project() do
    [
      app: :yy_scaffold,
      version: "2.0.0",
      elixir: "~> 1.6.2",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "YipYip Scaffold",
      source_url: "https://www.github.com/weareyipyip/YipYip-Phoenix-Scaffold"
    ]
  end

  def application() do
    [
      applications: []
    ]
  end

  defp description() do
    "A scaffolder made by YipYip to kickstart your umbrella Phoenix projects."
  end

  defp deps() do
    [
      {:dogma, "0.1.15", only: [:dev, :test]}
    ]
  end

  defp package() do
    [
      files: ["lib", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      maintainers: ["YipYip B.V.", "Thierry de Wit", "Maurice Schadee", "Evert Verboven"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://www.github.com/weareyipyip/YipYip-Phoenix-Scaffold",
        "YipYip" => "https://www.yipyip.nl"
      }
    ]
  end
end
