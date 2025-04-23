defmodule Onvif.Media.Profile.VideoAnalyticsConfiguration do
  @moduledoc """
  This element contains a list of Analytics configurations.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import SweetXml

  alias Onvif.Media.Profile.EngineConfig
  alias Onvif.Media.Profile.AnalyticsEngineConfiguration

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:reference_token, :string)
    field(:name, :string)
    field(:use_count, :integer)

    embeds_one(:analytics_engine_configuration, AnalyticsEngineConfiguration)

    embeds_one :rule_engine_configuration, RuleEngineConfiguration,
      primary_key: false,
      on_replace: :update do
      @derive Jason.Encoder
      embeds_many(:rule, EngineConfig)
    end
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      reference_token: ~x"./@token"s,
      name: ~x"./tt:Name/text()"s,
      use_count: ~x"./tt:UseCount/text()"i,
      analytics_engine_configuration:
        ~x"./tt:AnalyticsEngineConfiguration"e
        |> transform_by(&AnalyticsEngineConfiguration.parse/1),
      rule_engine_configuration:
        ~x"./tt:RuleEngineConfiguration"e |> transform_by(&parse_rule_engine_configuration/1)
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [:reference_token, :name, :use_count])
    |> cast_embed(:analytics_engine_configuration)
    |> cast_embed(:rule_engine_configuration, with: &rule_engine_configuration_changeset/2)
  end

  defp parse_rule_engine_configuration(nil), do: nil
  defp parse_rule_engine_configuration([]), do: nil

  defp parse_rule_engine_configuration(doc) do
    xmap(
      doc,
      rule: ~x"./tt:Rule"el |> transform_by(&parse_rules/1)
    )
  end

  defp parse_rules(doc) do
    doc
    |> List.wrap()
    |> Enum.map(&EngineConfig.parse/1)
  end

  defp rule_engine_configuration_changeset(module, attrs) do
    module
    |> cast(attrs, [])
    |> cast_embed(:rule)
  end
end
