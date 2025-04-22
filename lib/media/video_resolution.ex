defmodule Onvif.Media.VideoResolution do
  @moduledoc """
  Schema describing the resolution of a video stream.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:width, :integer)
    field(:height, :integer)
  end

  def parse(nil), do: nil

  def parse(doc) do
    xmap(
      doc,
      width: ~x"./tt:Width/text()"i,
      height: ~x"./tt:Height/text()"i
    )
  end

  def encode(%__MODULE__{} = video_resolution) do
    [
      XmlBuilder.element("tt:Width", video_resolution.width),
      XmlBuilder.element("tt:Height", video_resolution.height)
    ]
  end

  def changeset(video_resolution, attrs) do
    video_resolution
    |> cast(attrs, [:width, :height])
    |> validate_required([:width, :height])
  end
end
