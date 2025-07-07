defmodule ExOnvif.Media2.Profile.VideoEncoder do
  @moduledoc """
  VideoEncoder schema for Media Ver20
  """

  use Ecto.Schema

  import Ecto.Changeset
  import ExOnvif.Utils.XmlBuilder
  import SweetXml

  alias ExOnvif.Media.Profile.MulticastConfiguration
  alias ExOnvif.Media.VideoResolution

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:reference_token, :string)
    field(:name, :string)
    field(:use_count, :integer)
    field(:gov_length, :integer)
    field(:profile, :string)
    field(:guaranteed_frame_rate, :boolean, default: false)

    field(:encoding, Ecto.Enum, values: [jpeg: "JPEG", mpeg4: "MPEG4", h264: "H264", h265: "H265"])

    field(:quality, :float)

    embeds_one :resolution, VideoResolution, on_replace: :update

    embeds_one :rate_control, RateControl, primary_key: false, on_replace: :update do
      @derive Jason.Encoder
      field(:constant_bitrate, :boolean)
      field(:frame_rate_limit, :float)
      field(:bitrate_limit, :integer)
    end

    embeds_one(:multicast, MulticastConfiguration)
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      reference_token: ~x"./@token"s,
      profile: ~x"./@Profile"s,
      gov_length: ~x"./@GovLength"io,
      name: ~x"./tt:Name/text()"s,
      use_count: ~x"./tt:UseCount/text()"i,
      guaranteed_frame_rate: ~x"./tt:GuaranteedFrameRate/text()"s,
      encoding: ~x"./tt:Encoding/text()"s,
      quality: ~x"./tt:Quality/text()"f,
      resolution: ~x"./tt:Resolution"e |> transform_by(&VideoResolution.parse/1),
      rate_control: ~x"./tt:RateControl"e |> transform_by(&parse_rate_control/1),
      multicast: ~x"./tt:Multicast"e |> transform_by(&MulticastConfiguration.parse/1)
    )
  end

  def encode(video_encoder_config) do
    element(
      [],
      "tr2:Configuration",
      %{
        "token" => video_encoder_config.reference_token,
        "Profile" => video_encoder_config.profile,
        "GovLength" => video_encoder_config.gov_length
      },
      element("tt:Name", video_encoder_config.name)
      |> element("tt:UseCount", video_encoder_config.use_count)
      |> element(
        "tt:Encoding",
        Keyword.fetch!(
          Ecto.Enum.mappings(video_encoder_config.__struct__, :encoding),
          video_encoder_config.encoding
        )
      )
      |> element("tt:Quality", trunc(video_encoder_config.quality))
      |> element("tt:Resolution", VideoResolution.encode(video_encoder_config.resolution))
      |> rate_control_xml(video_encoder_config.rate_control)
      |> element("tt:Multicast", MulticastConfiguration.encode(video_encoder_config.multicast))
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [
      :reference_token,
      :name,
      :use_count,
      :profile,
      :gov_length,
      :guaranteed_frame_rate,
      :encoding,
      :quality
    ])
    |> cast_embed(:resolution)
    |> cast_embed(:rate_control, with: &rate_control_changeset/2)
    |> cast_embed(:multicast)
  end

  defp rate_control_xml(builder, rate_control) do
    element(
      builder,
      :"tt:RateControl",
      %{"ConstantBitRate" => rate_control.constant_bitrate},
      element("tt:FrameRateLimit", rate_control.frame_rate_limit)
      |> element("tt:BitrateLimit", rate_control.bitrate_limit)
    )
  end

  defp parse_rate_control(doc) do
    xmap(
      doc,
      constant_bitrate: ~x"./@ConstantBitRate"s,
      frame_rate_limit: ~x"./tt:FrameRateLimit/text()"f,
      bitrate_limit: ~x"./tt:BitrateLimit/text()"i
    )
  end

  defp rate_control_changeset(module, attrs) do
    cast(module, attrs, [:frame_rate_limit, :constant_bitrate, :bitrate_limit])
  end
end
