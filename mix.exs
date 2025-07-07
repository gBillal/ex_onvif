defmodule ExOnvif.MixProject do
  use Mix.Project

  @github_url "https://github.com/gBillal/onvif"

  def project do
    [
      app: :ex_onvif,
      version: "0.7.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),

      # ex_doc / hex
      name: "ExOnvif",
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
      mod: {ExOnvif.Application, []},
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
      main: "ExOnvif",
      extras: ["README.md"],
      nest_modules_by_prefix: [
        ExOnvif.Device,
        ExOnvif.Schemas,
        ExOnvif.Analytics,
        ExOnvif.Devices,
        ExOnvif.Event,
        ExOnvif.Media,
        ExOnvif.Media2,
        ExOnvif.Recording,
        ExOnvif.Replay,
        ExOnvif.Search,
        ExOnvif.PTZ
      ],
      groups_for_modules: [
        Core: [
          Onvif,
          ~r/^ExOnvif.Discovery.*/,
          ExOnvif.Device,
          ExOnvif.MacAddress,
          ExOnvif.Request,
          ExOnvif.Request.Header
        ],
        Interfaces: [
          ExOnvif.Devices,
          ExOnvif.Analytics,
          ExOnvif.Event,
          ExOnvif.PullPoint,
          ExOnvif.Media,
          ExOnvif.Media2,
          ExOnvif.Recording,
          ExOnvif.Replay,
          ExOnvif.Search,
          ExOnvif.PTZ
        ],
        Schemas: [
          ~r/^ExOnvif.Schemas.*/,
          ~r/^ExOnvif.Devices.*/,
          ~r/^ExOnvif.Event.*/,
          ~r/^ExOnvif.Media.*/,
          ~r/^ExOnvif.Media2.*/,
          ~r/^ExOnvif.Recording.*/,
          ~r/^ExOnvif.Replay.*/,
          ~r/^ExOnvif.Search.*/,
          ~r/^ExOnvif.PTZ.*/,
          ~r/^ExOnvif.Analytics.*/
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
