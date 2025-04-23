defmodule Onvif.Media2.VideoEncoderConfigurationOption do
  @moduledoc """
  Available options for video encoder configuration
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  alias Onvif.Schemas.{FloatRange, IntRange}
  alias Onvif.Media.VideoResolution

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:gov_length_range, {:array, :integer})
    field(:max_anchor_frame_distance, :integer)
    field(:frame_rates_supported, {:array, :float})
    field(:profiles_supported, {:array, :string})
    field(:constant_bit_rate_supported, :boolean)
    field(:guaranteed_frame_rate_supported, :boolean)
    field(:encoding, Ecto.Enum, values: [h264: "H264", h265: "H265", jpeg: "JPEG"])

    embeds_one :quality_range, FloatRange
    embeds_one :bitrate_range, IntRange
    embeds_many :resolutions_available, VideoResolution
  end

  def parse(doc) do
    xmap(
      doc,
      gov_length_range: ~x"./@GovLengthRange"s |> transform_by(&String.split(&1, " ")),
      max_anchor_frame_distance: ~x"./@MaxAnchorFrameDistance"I,
      frame_rates_supported: ~x"./@FrameRatesSupported"s |> transform_by(&String.split(&1, " ")),
      profiles_supported: ~x"./@ProfilesSupported"s |> transform_by(&String.split(&1, " ")),
      constant_bit_rate_supported: ~x"./@ConstantBitRateSupported"s,
      guaranteed_frame_rate_supported: ~x"./@GuaranteedFrameRateSupported"s,
      encoding: ~x"./tt:Encoding/text()"s,
      quality_range: ~x"./tt:QualityRange"e |> transform_by(&FloatRange.parse/1),
      resolutions_available:
        ~x"./tt:ResolutionsAvailable"el |> transform_by(&parse_resolutions_available/1),
      bitrate_range: ~x"./tt:BitrateRange"eo |> transform_by(&IntRange.parse/1)
    )
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [
      :gov_length_range,
      :max_anchor_frame_distance,
      :frame_rates_supported,
      :profiles_supported,
      :constant_bit_rate_supported,
      :guaranteed_frame_rate_supported,
      :encoding
    ])
    |> cast_embed(:quality_range)
    |> cast_embed(:resolutions_available)
    |> cast_embed(:bitrate_range)
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  defp parse_resolutions_available(resolutions),
    do: Enum.map(resolutions, &VideoResolution.parse/1)
end
