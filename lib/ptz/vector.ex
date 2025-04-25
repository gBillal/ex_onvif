defmodule Onvif.PTZ.Vector do
  @moduledoc """
  PTZ speed/vector schema
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml
  import XmlBuilder

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    embeds_one :pan_tilt, PanTilt, primary_key: false do
      @derive Jason.Encoder
      field :x, :float
      field :y, :float
      field :space, :string
    end

    field :zoom, :float
  end

  def new(x, y, zoom \\ nil) do
    %__MODULE__{
      pan_tilt: %__MODULE__.PanTilt{x: x, y: y},
      zoom: zoom
    }
  end

  def changeset(ptz_speed, attrs) do
    ptz_speed
    |> cast(attrs, [:zoom])
    |> cast_embed(:pan_tilt, with: &pan_tilt_changeset/2)
  end

  def encode(nil), do: []

  def encode(%__MODULE__{zoom: zoom, pan_tilt: pan_tilt}) do
    body = if zoom, do: [element("tptz:Zoom", %{x: zoom})], else: []
    body ++ pan_tilt_xml(pan_tilt)
  end

  def parse(doc) do
    xmap(
      doc,
      pan_tilt: ~x"./tt:PanTilt" |> transform_by(&parse_pan_tilt/1),
      zoom: ~x"./tt:Zoom/@x"s
    )
  end

  defp parse_pan_tilt(doc) do
    xmap(
      doc,
      x: ~x"./@x"s,
      y: ~x"./@y"s,
      space: ~x"./@space"s
    )
  end

  defp pan_tilt_changeset(pan_tilt, attrs) do
    pan_tilt
    |> cast(attrs, [:x, :y, :space])
    |> validate_required([:x, :y])
  end

  defp pan_tilt_xml(nil), do: []
  defp pan_tilt_xml(%__MODULE__.PanTilt{x: nil, y: nil}), do: []

  defp pan_tilt_xml(%__MODULE__.PanTilt{x: x, y: y}) do
    [x: x, y: y]
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
    |> then(&[element("tptz:PanTilt", &1)])
  end
end
