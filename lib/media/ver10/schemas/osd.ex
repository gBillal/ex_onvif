defmodule Onvif.Media.Ver10.Schemas.OSD do
  @moduledoc """
  OSD (On-Screen Display) specification.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Onvif.Utils.XmlBuilder
  import SweetXml

  alias Onvif.Media.OSD.Color

  @required [:token, :video_source_configuration_token, :type]
  @optional []

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:token, :string)
    field(:video_source_configuration_token, :string)
    field(:type, Ecto.Enum, values: [text: "Text", image: "Image", extended: "Extended"])

    embeds_one :position, Position, primary_key: false, on_replace: :update do
      @derive Jason.Encoder
      field(:type, Ecto.Enum,
        values: [
          upper_left: "UpperLeft",
          upper_right: "UpperRight",
          lower_left: "LowerLeft",
          lower_right: "LowerRight",
          custom: "Custom"
        ]
      )

      field(:pos, :map)
    end

    embeds_one :text_string, TextString, primary_key: false, on_replace: :update do
      @derive Jason.Encoder
      field(:is_persistent_text, :boolean)

      field(:type, Ecto.Enum,
        values: [plain: "Plain", date: "Date", time: "Time", date_and_time: "DateAndTime"]
      )

      field(:date_format, :string)
      field(:time_format, :string)
      field(:font_size, :integer)

      embeds_one(:font_color, Color, on_replace: :update)
      embeds_one(:background_color, Color, on_replace: :update)

      field(:plain_text, :string)
    end

    embeds_one :image, Image, primary_key: false, on_replace: :update do
      @derive Jason.Encoder
      field(:image_path, :string)
    end
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      token: ~x"//@token"so,
      video_source_configuration_token: ~x"./tt:VideoSourceConfigurationToken/text()"so,
      type: ~x"./tt:Type/text()"so,
      position: ~x"./tt:Position"eo |> transform_by(&parse_position/1),
      text_string: ~x"./tt:TextString"eo |> transform_by(&parse_text_string/1),
      image: ~x"./tt:Image"eo |> transform_by(&parse_image/1)
    )
  end

  def encode(%__MODULE__{} = osd) do
    element(
      [],
      :"trt:OSD",
      %{token: osd.token},
      element(:"tt:VideoSourceConfigurationToken", osd.video_source_configuration_token)
      |> element(:"tt:Type", Keyword.fetch!(Ecto.Enum.mappings(osd.__struct__, :type), osd.type))
      |> element(
        "tt:Position",
        []
        |> element("tt:Pos", %{x: osd.position.pos.x, y: osd.position.pos.y}, nil)
        |> element(
          "tt:Type",
          Keyword.fetch!(Ecto.Enum.mappings(osd.position.__struct__, :type), osd.position.type)
        )
      )
      |> gen_element_type(osd.type, osd)
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
    |> cast_embed(:position, with: &position_changeset/2)
    |> cast_embed(:text_string, with: &text_string_changeset/2)
    |> cast_embed(:image, with: &image_changeset/2)
  end

  defp parse_position([]), do: nil
  defp parse_position(nil), do: nil

  defp parse_position(doc) do
    xmap(
      doc,
      type: ~x"./tt:Type/text()"so,
      pos: ~x"./tt:Pos"eo |> transform_by(&parse_pos/1)
    )
  end

  defp parse_pos([]), do: nil
  defp parse_pos(nil), do: nil

  defp parse_pos(doc) do
    %{
      x: doc |> xpath(~x"./@x"s),
      y: doc |> xpath(~x"./@y"s)
    }
  end

  defp parse_text_string([]), do: nil
  defp parse_text_string(nil), do: nil

  defp parse_text_string(doc) do
    xmap(
      doc,
      is_persistent_text: ~x"./tt:IsPersistentText/text()"so,
      type: ~x"./tt:Type/text()"so,
      date_format: ~x"./tt:DateFormat/text()"so,
      time_format: ~x"./tt:TimeFormat/text()"so,
      font_size: ~x"./tt:FontSize/text()"io,
      font_color: ~x"./tt:FontColor"eo |> transform_by(&Color.parse/1),
      background_color: ~x"./tt:BackgroundColor"eo |> transform_by(&Color.parse/1),
      plain_text: ~x"./tt:PlainText/text()"so
    )
  end

  defp parse_image([]), do: nil
  defp parse_image(nil), do: nil

  defp parse_image(doc) do
    xmap(
      doc,
      image_path: ~x"./tt:ImagePath/text()"so
    )
  end

  defp position_changeset(module, attrs) do
    cast(module, attrs, [:type, :pos])
  end

  defp text_string_changeset(module, attrs) do
    cast(module, attrs, [
      :is_persistent_text,
      :type,
      :date_format,
      :time_format,
      :font_size,
      :plain_text
    ])
    |> cast_embed(:font_color, with: &color_changeset/2)
    |> cast_embed(:background_color, with: &color_changeset/2)
    |> validate_inclusion(:date_format, [
      "M/d/yyyy",
      "MM/dd/yyyy",
      "dd/MM/yyyy",
      "yyyy/MM/dd",
      "yyyy-MM-dd",
      "dddd, MMMM dd, yyyy",
      "MMMM dd, yyyy",
      "dd MMMM, yyyy"
    ])
    |> validate_inclusion(:time_format, [
      "h:mm:ss tt",
      "hh:mm:ss tt",
      "H:mm:ss",
      "HH:mm:ss"
    ])
  end

  defp color_changeset(module, attrs) do
    cast(module, attrs, [:transparent, :color])
  end

  defp image_changeset(module, attrs) do
    cast(module, attrs, [:image_path])
  end

  defp gen_element_type(builder, :text, osd) do
    element(builder, :"tt:TextString", gen_text_string(osd))
  end

  defp gen_element_type(builder, :image, osd) do
    image_element(builder, osd.image)
  end

  defp gen_text_string(osd) do
    element("tt:IsPersistentText", osd.text_string.is_persistent_text)
    |> element(
      :"tt:Type",
      Keyword.fetch!(
        Ecto.Enum.mappings(osd.text_string.__struct__, :type),
        osd.text_string.type
      )
    )
    |> element("tt:FontSize", osd.text_string.font_size)
    |> element("tt:FontColor", Color.encode(osd.text_string.font_color))
    |> element("tt:BackgroundColor", Color.encode(osd.text_string.background_color))
    |> gen_text_type(osd.text_string.type, osd)
  end

  defp gen_text_type(builder, :plain, osd) do
    element(builder, "tt:PlainText", osd.text_string.plain_text)
  end

  defp gen_text_type(builder, :date, osd) do
    element(builder, "tt:DateFormat", osd.text_string.date_format)
  end

  defp gen_text_type(builder, :time, osd) do
    element(builder, "tt:TimeFormat", osd.text_string.time_format)
  end

  defp gen_text_type(builder, :date_and_time, osd) do
    builder
    |> element("tt:DateFormat", osd.text_string.date_format)
    |> element("tt:TimeFormat", osd.text_string.time_format)
  end

  defp image_element(builder, nil), do: builder

  defp image_element(builder, %__MODULE__.Image{} = image) do
    element(builder, "tt:Image", element("tt:ImagePath", image.image_path))
  end
end
