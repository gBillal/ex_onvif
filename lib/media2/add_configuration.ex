defmodule ExOnvif.Media2.AddConfiguration do
  @moduledoc """
  Schema describing a request to add a configuration to the media service.
  """

  use TypedEctoSchema

  import Ecto.Changeset
  import ExOnvif.Utils.XmlBuilder

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :profile_token, :string
    field :name, :string

    embeds_many :configuration, Configuration, primary_key: false do
      field :type, :string
      field :token, :string
    end
  end

  def encode(struct) do
    element(
      "tr2:AddConfiguration",
      element("tr2:ProfileToken", struct.profile_token)
      |> element("tr2:Name", struct.name)
      |> encode_configuration(struct.configuration)
    )
  end

  def changeset(add_configuration, attrs) do
    add_configuration
    |> cast(attrs, [:profile_token, :name])
    |> validate_required([:profile_token])
    |> cast_embed(:configuration, with: &configuration_changeset/2)
  end

  defp encode_configuration(builder, configs) do
    Enum.reduce(configs, builder, fn config, builder ->
      element(
        builder,
        "tr2:Configuration",
        element("tt:Type", config.type)
        |> element("tt:Token", config.token)
      )
    end)
  end

  defp configuration_changeset(configuration, attrs) do
    configuration
    |> cast(attrs, [:type, :token])
  end
end
