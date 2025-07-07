defmodule ExOnvif.Media.OSD.ColorOptions do
  @moduledoc """
  Schema for the color options of the OSD (On-Screen Display) in ExOnvif.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  alias ExOnvif.Schemas.IntRange
  alias ExOnvif.Schemas.FloatRange

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    embeds_one :color, Color, primary_key: false, on_replace: :update do
      @derive Jason.Encoder
      field(:color_list, {:array, :string})

      embeds_one :color_space_range, ColorSpaceRange, primary_key: false, on_replace: :update do
        @derive Jason.Encoder
        field(:color_space, :string)

        embeds_one(:x, FloatRange, on_replace: :update)
        embeds_one(:y, FloatRange, on_replace: :update)
        embeds_one(:z, FloatRange, on_replace: :update)
      end
    end

    embeds_one(:transparent, IntRange, on_replace: :update)
  end

  def parse(nil), do: nil

  def parse(doc) do
    xmap(
      doc,
      color: ~x"./tt:Color"eo |> transform_by(&parse_color/1),
      transparent: ~x"./tt:Transparent"eo |> transform_by(&IntRange.parse/1)
    )
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [])
    |> cast_embed(:transparent, with: &IntRange.parse/1)
    |> cast_embed(:color, with: &color_changeset/2)
  end

  defp color_changeset(struct, params) do
    struct
    |> cast(params, [:color_list])
    |> cast_embed(:color_space_range, with: &color_space_range_changeset/2)
  end

  defp color_space_range_changeset(struct, params) do
    struct
    |> cast(params, [:color_space])
    |> cast_embed(:x, with: &FloatRange.changeset/2)
    |> cast_embed(:y, with: &FloatRange.changeset/2)
    |> cast_embed(:z, with: &FloatRange.changeset/2)
  end

  defp parse_color(nil), do: nil

  defp parse_color(doc) do
    xmap(
      doc,
      color_list: ~x"./tt:ColorList"so |> transform_by(&String.split(&1, ",")),
      color_space_range: ~x"./tt:ColorspaceRange"eo |> transform_by(&parse_color_space_range/1)
    )
  end

  defp parse_color_space_range([]), do: nil
  defp parse_color_space_range(nil), do: nil

  defp parse_color_space_range(doc) do
    xmap(
      doc,
      x: ~x"./tt:X"eo |> transform_by(&FloatRange.parse/1),
      y: ~x"./tt:Y"eo |> transform_by(&FloatRange.parse/1),
      z: ~x"./tt:Z"eo |> transform_by(&FloatRange.parse/1),
      color_space: ~x"./tt:Colorspace/text()"so
    )
  end
end
