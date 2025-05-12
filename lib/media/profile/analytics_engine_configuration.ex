defmodule Onvif.Media.Profile.AnalyticsEngineConfiguration do
  @moduledoc """
  Indication which AnalyticsModules shall output metadata. Note that the streaming behavior is undefined if the list
  includes items that are not part of the associated AnalyticsConfiguration.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  alias Onvif.Analytics.Module

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    embeds_many :analytics_module, Module
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      analytics_module: ~x"./tt:AnalyticsModule"el |> transform_by(&parse_analytics_engines/1)
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [])
    |> cast_embed(:analytics_module)
  end

  defp parse_analytics_engines(analytics_engines) do
    analytics_engines
    |> List.wrap()
    |> Enum.map(&Module.parse/1)
  end
end
