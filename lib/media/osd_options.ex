defmodule Onvif.Media.OSDOptions do
  @moduledoc """
  OSD (On-Screen Display) Options specification.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import SweetXml

  alias Onvif.Media.OSD.ColorOptions
  alias Onvif.Schemas.IntRange

  @required [:type, :position_option]
  @optional []

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:type, {:array, :string})
    field(:position_option, {:array, :string})

    embeds_one :maximum_number_of_osds, MaximumNumberOfOSDs,
      primary_key: false,
      on_replace: :update do
      @derive Jason.Encoder
      field(:total, :integer)
      field(:image, :integer)
      field(:plaintext, :integer)
      field(:date, :integer)
      field(:time, :integer)
      field(:date_and_time, :integer)
    end

    embeds_one :text_option, TextOption, primary_key: false, on_replace: :update do
      @derive Jason.Encoder
      field(:type, {:array, :string})

      embeds_one(:font_size_range, IntRange, on_replace: :update)

      field(:date_format, {:array, :string})
      field(:time_format, {:array, :string})

      embeds_one(:font_color, ColorOptions, on_replace: :update)
      embeds_one(:background_color, ColorOptions, on_replace: :update)
    end

    embeds_one :image_option, ImageOption, primary_key: false, on_replace: :update do
      field(:formats_supported, {:array, :string})
      field(:max_size, :integer)
      field(:max_width, :integer)
      field(:max_height, :integer)
      field(:image_path, :string)
    end
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      type: ~x"./tt:Type/text()"slo,
      position_option: ~x"./tt:PositionOption/text()"slo,
      maximum_number_of_osds:
        ~x"./tt:MaximumNumberOfOSDs"eo |> transform_by(&parse_maximum_number_of_osds/1),
      text_option: ~x"./tt:TextOption"eo |> transform_by(&parse_text_option/1),
      image_option: ~x"./tt:ImageOption"eo |> transform_by(&parse_image_option/1)
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(osd_options, params \\ %{}) do
    osd_options
    |> cast(params, @required ++ @optional)
    |> validate_required(@required)
    |> cast_embed(:maximum_number_of_osds, with: &maximum_number_of_osds_changeset/2)
    |> cast_embed(:text_option, with: &text_option_changeset/2)
    |> cast_embed(:image_option, with: &image_option_changeset/2)
    |> validate_subset(:type, ["Image", "Text", "Extended"])
    |> validate_subset(:position_option, [
      "UpperLeft",
      "UpperRight",
      "LowerLeft",
      "LowerRight",
      "Custom"
    ])
  end

  defp parse_text_option([]), do: nil
  defp parse_text_option(nil), do: nil

  defp parse_text_option(doc) do
    xmap(
      doc,
      type: ~x"./tt:Type/text()"slo,
      font_size_range: ~x"./tt:FontSizeRange"eo |> transform_by(&IntRange.parse/1),
      date_format: ~x"./tt:DateFormat/text()"slo,
      time_format: ~x"./tt:TimeFormat/text()"slo,
      font_color: ~x"./tt:FontColor"eo |> transform_by(&ColorOptions.parse/1),
      background_color: ~x"./tt:BackgroundColor"eo |> transform_by(&ColorOptions.parse/1)
    )
  end

  defp parse_maximum_number_of_osds([]), do: nil
  defp parse_maximum_number_of_osds(nil), do: nil

  defp parse_maximum_number_of_osds(doc) do
    xmap(
      doc,
      total: ~x"//@Total"so,
      image: ~x"//@Image"so,
      plaintext: ~x"//@PlainText"so,
      date: ~x"//@Date"so,
      time: ~x"//@Time"so,
      date_and_time: ~x"//@DateAndTime"so
    )
  end

  defp parse_image_option([]), do: nil
  defp parse_image_option(nil), do: nil

  defp parse_image_option(doc) do
    xmap(
      doc,
      formats_supported: ~x"./tt:FormatsSupported/text()"so,
      max_size: ~x"//@MaxSize"so,
      max_width: ~x"//@MaxWidth"so,
      max_height: ~x"//@MaxHeight"so,
      image_path: ~x"./tt:ImagePath/text()"so
    )
  end

  defp maximum_number_of_osds_changeset(module, attrs) do
    cast(module, attrs, [:total, :image, :plaintext, :date, :time, :date_and_time])
  end

  defp text_option_changeset(module, attrs) do
    cast(module, attrs, [:type, :date_format, :time_format])
    |> cast_embed(:font_size_range, with: &IntRange.changeset/2)
    |> cast_embed(:font_color, with: &ColorOptions.changeset/2)
    |> cast_embed(:background_color, with: &ColorOptions.changeset/2)
  end

  defp image_option_changeset(module, attrs) do
    cast(module, attrs, [:formats_supported, :max_size, :max_width, :max_height, :image_path])
  end
end
