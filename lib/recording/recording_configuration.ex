defmodule ExOnvif.Recording.RecordingConfiguration do
  @moduledoc """
  Schema describing recording configuration.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml
  import XmlBuilder

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:content, :string)
    field(:maximum_retention_time, :string)

    embeds_one :source, Source, primary_key: false do
      @derive Jason.Encoder
      field(:source_id, :string)
      field(:name, :string)
      field(:location, :string)
      field(:description, :string)
      field(:address, :string)
    end
  end

  def parse([]), do: nil
  def parse(nil), do: nil

  def parse(doc) do
    xmap(
      doc,
      content: ~x"./tt:Content/text()"so,
      maximum_retention_time: ~x"./tt:MaximumRetentionTime/text()"so,
      source: ~x"./tt:Source"eo |> transform_by(&parse_source/1)
    )
  end

  def encode(%__MODULE__{} = recording_configuration) do
    element(:"trc:ConfigurationConfiguration", [
      element(:"tt:Source", [
        element(:"tt:SourceId", recording_configuration.source.source_id),
        element(:"tt:Name", recording_configuration.source.name),
        element(:"tt:Location", recording_configuration.source.location),
        element(:"tt:Description", recording_configuration.source.description),
        element(:"tt:Address", recording_configuration.source.address)
      ]),
      gen_content(recording_configuration.content),
      gen_maximum_retention_time(recording_configuration.maximum_retention_time)
    ])
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [:content, :maximum_retention_time])
    |> cast_embed(:source, with: &source_changeset/2)
  end

  defp parse_source([]), do: nil
  defp parse_source(nil), do: nil

  defp parse_source(doc) do
    xmap(
      doc,
      source_id: ~x"./tt:SourceId/text()"so,
      name: ~x"./tt:Name/text()"so,
      location: ~x"./tt:Location/text()"so,
      description: ~x"./tt:Description/text()"so,
      address: ~x"./tt:Address/text()"so
    )
  end

  defp source_changeset(module, attrs) do
    cast(module, attrs, [:source_id, :name, :location, :description, :address])
  end

  defp gen_content(nil), do: []
  defp gen_content(content), do: element(:"tt:Content", content)

  defp gen_maximum_retention_time(nil), do: []

  defp gen_maximum_retention_time(maximum_retention_time),
    do: element(:"tt:MaximumRetentionTime", maximum_retention_time)
end
