defmodule Onvif.Recording.RecordingConfiguration do
  @moduledoc """
  Schema describing recording configuration.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml
  import XmlBuilder

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

  def parse(doc) do
    xmap(
      doc,
      recording_token: ~x"./tt:RecordingToken/text()"so,
      configuration: ~x"./tt:Configuration"eo |> transform_by(&parse_configuration/1),
      tracks: ~x"./tt:Tracks"eo |> transform_by(&parse_tracks/1)
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

  defp parse_configuration([]), do: nil
  defp parse_configuration(nil), do: nil

  defp parse_configuration(doc) do
    xmap(
      doc,
      content: ~x"./tt:Content/text()"so,
      maximum_retention_time: ~x"./tt:MaximumRetentionTime/text()"so,
      source: ~x"./tt:Source"eo |> transform_by(&parse_source/1)
    )
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

  defp parse_tracks([]), do: nil
  defp parse_tracks(nil), do: nil

  defp parse_tracks(doc) do
    xmap(
      doc,
      track: ~x"./tt:Track"elo |> transform_by(&parse_track/1)
    )
  end

  defp parse_track([]), do: nil
  defp parse_track(nil), do: nil

  defp parse_track(docs) do
    Enum.map(docs, fn doc ->
      xmap(
        doc,
        track_token: ~x"./tt:TrackToken/text()"so,
        configuration: ~x"./tt:Configuration"eo |> transform_by(&parse_track_configuration/1)
      )
    end)
  end

  defp parse_track_configuration([]), do: nil
  defp parse_track_configuration(nil), do: nil

  defp parse_track_configuration(doc) do
    xmap(
      doc,
      track_type: ~x"./tt:TrackType/text()"so,
      description: ~x"./tt:Description/text()"so
    )
  end

  defp source_changeset(module, attrs) do
    cast(module, attrs, [:source_id, :name, :location, :description, :address])
  end

  def gen_content(nil), do: []
  def gen_content(content), do: element(:"tt:Content", content)

  def gen_maximum_retention_time(nil), do: []

  def gen_maximum_retention_time(maximum_retention_time),
    do: element(:"tt:MaximumRetentionTime", maximum_retention_time)
end
