defmodule Onvif.MixProject do
  use Mix.Project

  @github_url "https://github.com/gBillal/onvif"

  def project do
    [
      app: :onvif,
      version: "0.7.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),

      # ex_doc / hex
      name: "Onvif",
      source_url: @github_url,
      description: "Elixir interface for Onvif functions",
      docs: docs(),
      package: [
        licenses: ["BSD-3-Clause"],
        links: %{
          "GitHub" => @github_url
        }
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Onvif.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.12"},
      {:finch, "~> 0.19"},
      {:sweet_xml, "~> 0.7"},
      {:tesla, "~> 1.13"},
      {:xml_builder, "~> 2.3"},
      {:jason, "~> 1.4"},
      {:typed_ecto_schema, "~> 0.4.1", runtime: false},
      {:ex_doc, "~> 0.36", only: :dev, runtime: false},
      {:mimic, "~> 1.7.4", only: :test}
    ]
  end

  defp docs do
    [
      main: "Onvif",
      extras: ["README.md"],
      nest_modules_by_prefix: [
        Onvif.Device,
        Onvif.Schemas,
        Onvif.Analytics,
        Onvif.Devices,
        Onvif.Event,
        Onvif.Media,
        Onvif.Media2,
        Onvif.Recording,
        Onvif.Replay,
        Onvif.Search,
        Onvif.PTZ
      ],
      groups_for_modules: [
        Core: [
          Onvif,
          ~r/^Onvif.Discovery.*/,
          Onvif.Device,
          Onvif.MacAddress,
          Onvif.Request,
          Onvif.Request.Header
        ],
        Interfaces: [
          Onvif.Devices,
          Onvif.Analytics,
          Onvif.Event,
          Onvif.PullPoint,
          Onvif.Media,
          Onvif.Media2,
          Onvif.Recording,
          Onvif.Replay,
          Onvif.Search,
          Onvif.PTZ
        ],
        Schemas: [
          ~r/^Onvif.Schemas.*/,
          ~r/^Onvif.Devices.*/,
          ~r/^Onvif.Event.*/,
          ~r/^Onvif.Media.*/,
          ~r/^Onvif.Media2.*/,
          ~r/^Onvif.Recording.*/,
          ~r/^Onvif.Replay.*/,
          ~r/^Onvif.Search.*/,
          ~r/^Onvif.PTZ.*/,
          ~r/^Onvif.Analytics.*/
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
