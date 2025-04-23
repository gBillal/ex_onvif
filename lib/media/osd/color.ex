defmodule Onvif.Media.OSD.Color do
  @moduledoc """
  A schema describing an OSD color.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Onvif.Utils.XmlBuilder
  import SweetXml

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:transparent, :boolean)
    field(:color, :map)
  end

  def parse(nil), do: nil

  def parse(doc) do
    xmap(
      doc,
      transparent: ~x"./tt:Transparent/text()"so,
      color: ~x"./tt:Color"eo |> transform_by(&parse_inner_color/1)
    )
  end

  def encode(nil), do: nil

  def encode(%__MODULE__{color: color}) do
    element(
      [],
      "tt:Color",
      %{
        X: color.x,
        Y: color.y,
        Z: color.z,
        Colorspace: color.colorspace
      },
      nil
    )
  end

  def changeset(module, attrs) do
    cast(module, attrs, [:transparent, :color])
  end

  defp parse_inner_color([]), do: nil
  defp parse_inner_color(nil), do: nil

  defp parse_inner_color(doc) do
    %{
      x: doc |> xpath(~x"./@X"s),
      y: doc |> xpath(~x"./@Y"s),
      z: doc |> xpath(~x"./@Z"s),
      colorspace: doc |> xpath(~x"./@Colorspace"s)
    }
  end
end
