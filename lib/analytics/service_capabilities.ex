defmodule ExOnvif.Analytics.ServiceCapabilities do
  @moduledoc """
  Schema describing the capabilities of the analytics service.
  """

  use TypedEctoSchema

  import Ecto.Changeset
  import SweetXml

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :rule_support, :boolean, default: false
    field :analytics_module_support, :boolean, default: false
    field :cell_based_scene_description_supported, :boolean, default: false
    field :rule_options_supported, :boolean, default: false
    field :analytics_module_options_supported, :boolean, default: false
    field :supported_metadata, :boolean, default: false
    field :image_sending_type, {:array, :string}
  end

  def parse(doc) do
    xmap(doc,
      rule_support: ~x"./@RuleSupport"s,
      analytics_module_support: ~x"./@AnalyticsModuleSupport"s,
      cell_based_scene_description_supported: ~x"./@CellBasedSceneDescriptionSupported"s,
      rule_options_supported: ~x"./@RuleOptionsSupported"s,
      analytics_module_options_supported: ~x"./@AnalyticsModuleOptionsSupported"s,
      supported_metadata: ~x"./@SupportedMetadata"s,
      image_sending_type: ~x"./@ImageSendingType"s |> transform_by(&String.split(&1, " "))
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, __MODULE__.__schema__(:fields))
  end
end
