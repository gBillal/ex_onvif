defmodule ExOnvif.PTZ.Vector do
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
    field :zoom_space, :string
  end

  # 2-argument version (zoom defaults to nil)
  def new(x, y) do
    %__MODULE__{
      pan_tilt: %__MODULE__.PanTilt{x: x, y: y},
      zoom: nil
    }
  end

  # 3-argument version with zoom
  def new(x, y, zoom) when is_float(zoom) or is_nil(zoom) do
    %__MODULE__{
      pan_tilt: %__MODULE__.PanTilt{x: x, y: y},
      zoom: zoom
    }
  end

  # 3-argument version with options (keyword list)
  def new(x, y, opts) when is_list(opts) and is_list(hd(opts)) == false do
    # Guard ensures opts is a keyword list, not nested lists
    pan_tilt_space = Keyword.get(opts, :pan_tilt_space)
    zoom = Keyword.get(opts, :zoom)
    zoom_space = Keyword.get(opts, :zoom_space)

    %__MODULE__{
      pan_tilt: %__MODULE__.PanTilt{x: x, y: y, space: pan_tilt_space},
      zoom: zoom,
      zoom_space: zoom_space
    }
  end

  def changeset(ptz_speed, attrs) do
    ptz_speed
    |> cast(attrs, [:zoom])
    |> cast_embed(:pan_tilt, with: &pan_tilt_changeset/2)
  end

  def encode(nil), do: []

  def encode(%__MODULE__{zoom: zoom, zoom_space: zoom_space, pan_tilt: pan_tilt}) do
    body =
      if zoom do
        attrs = if zoom_space, do: %{x: zoom, space: zoom_space}, else: %{x: zoom}
        [element("tt:Zoom", attrs)]
      else
        []
      end

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

  defp pan_tilt_xml(%__MODULE__.PanTilt{x: x, y: y, space: space}) do
    [x: x, y: y, space: space]
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
    |> then(&[element("tt:PanTilt", &1)])
  end
end
