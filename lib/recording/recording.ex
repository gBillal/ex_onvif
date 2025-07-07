defmodule ExOnvif.Recording.Recording do
  @moduledoc """
  ExOnvif.Recording.Recordings schema.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import SweetXml

  alias ExOnvif.Recording.RecordingConfiguration

  @required [:recording_token]
  @optional []

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:recording_token, :string)

    embeds_one(:configuration, RecordingConfiguration)

    embeds_one(:tracks, Tracks, primary_key: false, on_replace: :update) do
      @derive Jason.Encoder
      embeds_many(:track, Track, primary_key: false, on_replace: :delete) do
        @derive Jason.Encoder
        field(:track_token, :string)

        embeds_one(:configuration, Configuration, primary_key: false, on_replace: :update) do
          @derive Jason.Encoder
          field(:track_type, :string)
          field(:description, :string)
        end
      end
    end
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      recording_token: ~x"./tt:RecordingToken/text()"so,
      configuration: ~x"./tt:Configuration"eo |> transform_by(&RecordingConfiguration.parse/1),
      tracks: ~x"./tt:Tracks"eo |> transform_by(&parse_tracks/1)
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> cast_embed(:configuration, with: &RecordingConfiguration.changeset/2)
    |> cast_embed(:tracks, with: &tracks_changeset/2)
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

  defp tracks_changeset(module, attrs) do
    cast(module, attrs, [])
    |> cast_embed(:track, with: &track_changeset/2)
  end

  defp track_changeset(module, attrs) do
    cast(module, attrs, [:track_token])
    |> cast_embed(:configuration, with: &track_configuration_changeset/2)
  end

  defp track_configuration_changeset(module, attrs) do
    cast(module, attrs, [:track_type, :description])
  end
end
