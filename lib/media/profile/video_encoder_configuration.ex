defmodule ExOnvif.Media.Profile.VideoEncoderConfiguration do
  @moduledoc """
  Configurations for the video encoding
  """

  use Ecto.Schema

  import Ecto.Changeset
  import ExOnvif.Utils.XmlBuilder
  import SweetXml

  alias ExOnvif.Media.VideoResolution
  alias ExOnvif.Media.Profile.MulticastConfiguration

  @required [:reference_token, :name, :encoding]
  @optional [:use_count, :guaranteed_frame_rate, :quality, :session_timeout]

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:reference_token, :string)
    field(:name, :string)
    field(:use_count, :integer)
    field(:guaranteed_frame_rate, :boolean, default: false)
    field(:encoding, Ecto.Enum, values: [jpeg: "JPEG", mpeg4: "MPEG4", h264: "H264"])
    field(:quality, :float)
    field(:session_timeout, :string)

    embeds_one(:resolution, VideoResolution, on_replace: :update)

    embeds_one :rate_control, RateControl, primary_key: false, on_replace: :update do
      @derive Jason.Encoder
      field(:frame_rate_limit, :integer)
      field(:encoding_interval, :integer)
      field(:bitrate_limit, :integer)
    end

    embeds_one :mpeg4_configuration, Mpeg4Configuration, primary_key: false, on_replace: :update do
      @derive Jason.Encoder
      field(:gov_length, :integer)
      field(:mpeg4_profile, Ecto.Enum, values: [simple: "SP", advanced_simple: "ASP"])
    end

    embeds_one :h264_configuration, H264Configuration, primary_key: false, on_replace: :update do
      @derive Jason.Encoder
      field(:gov_length, :integer)

      field(:h264_profile, Ecto.Enum,
        values: [baseline: "Baseline", main: "Main", extended: "Extended", high: "High"]
      )
    end

    embeds_one(:multicast, MulticastConfiguration)
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      reference_token: ~x"./@token"so,
      name: ~x"./tt:Name/text()"so,
      use_count: ~x"./tt:UseCount/text()"io,
      guaranteed_frame_rate: ~x"./tt:GuaranteedFrameRate/text()"so,
      encoding: ~x"./tt:Encoding/text()"so,
      session_timeout: ~x"./tt:SessionTimeout/text()"so,
      quality: ~x"./tt:Quality/text()"fo,
      resolution: ~x"./tt:Resolution"eo |> transform_by(&VideoResolution.parse/1),
      rate_control: ~x"./tt:RateControl"eo |> transform_by(&parse_rate_control/1),
      mpeg4_configuration: ~x"./tt:Mpeg4"eo |> transform_by(&parse_mpeg4_configuration/1),
      h264_configuration: ~x"./tt:H264"eo |> transform_by(&parse_h264_configuration/1),
      multicast: ~x"./tt:Multicast"eo |> transform_by(&MulticastConfiguration.parse/1)
    )
  end

  def encode(%__MODULE__{} = video_encoder_config, name) do
    element(
      [],
      name,
      %{token: video_encoder_config.reference_token},
      element(:"tt:Name", video_encoder_config.name)
      |> element(:"tt:UseCount", video_encoder_config.use_count)
      |> element(:"tt:GuaranteedFrameRate", video_encoder_config.guaranteed_frame_rate)
      |> element(
        :"tt:Encoding",
        Keyword.fetch!(Ecto.Enum.mappings(__MODULE__, :encoding), video_encoder_config.encoding)
      )
      |> element("tt:Quality", video_encoder_config.quality)
      |> element("tt:Resolution", VideoResolution.encode(video_encoder_config.resolution))
      |> element("tt:RateControl", rate_control_element(video_encoder_config.rate_control))
      |> encoder_config_element(video_encoder_config)
      |> element(
        "tt:Multicast",
        MulticastConfiguration.encode(video_encoder_config.multicast)
      )
      |> element(:"tt:SessionTimeout", video_encoder_config.session_timeout)
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
    |> cast_embed(:resolution, with: &VideoResolution.changeset/2)
    |> cast_embed(:rate_control, with: &rate_control_changeset/2)
    |> cast_embed(:mpeg4_configuration, with: &mpeg4_configuration_changeset/2)
    |> cast_embed(:h264_configuration, with: &h264_configuration_changeset/2)
    |> cast_embed(:multicast)
  end

  defp rate_control_element(rate_control) do
    element(:"tt:FrameRateLimit", rate_control.frame_rate_limit)
    |> element(:"tt:EncodingInterval", rate_control.encoding_interval)
    |> element(:"tt:BitrateLimit", rate_control.bitrate_limit)
  end

  defp encoder_config_element(builder, %__MODULE__{
         h264_configuration: nil,
         mpeg4_configuration: nil
       }) do
    builder
  end

  defp encoder_config_element(builder, %__MODULE__{
         h264_configuration: h264_configuration,
         mpeg4_configuration: nil
       }) do
    element(
      builder,
      :"tt:H264",
      element(:"tt:GovLength", h264_configuration.gov_length)
      |> element(
        :"tt:H264Profile",
        Keyword.fetch!(
          Ecto.Enum.mappings(h264_configuration.__struct__, :h264_profile),
          h264_configuration.h264_profile
        )
      )
    )
  end

  defp encoder_config_element(builder, %__MODULE__{
         h264_configuration: nil,
         mpeg4_configuration: mpeg4_configuration
       }) do
    element(
      builder,
      :"tt:MPEG4",
      element(:"tt:GovLength", mpeg4_configuration.gov_length)
      |> element(
        :"tt:Mpeg4Profile",
        Keyword.fetch!(
          Ecto.Enum.mappings(mpeg4_configuration.__struct__, :mpeg4_profile),
          mpeg4_configuration.mpeg4_profile
        )
      )
    )
  end

  defp parse_rate_control([]), do: nil
  defp parse_rate_control(nil), do: nil

  defp parse_rate_control(doc) do
    xmap(
      doc,
      frame_rate_limit: ~x"./tt:FrameRateLimit/text()"i,
      encoding_interval: ~x"./tt:EncodingInterval/text()"i,
      bitrate_limit: ~x"./tt:BitrateLimit/text()"i
    )
  end

  defp parse_mpeg4_configuration([]), do: nil
  defp parse_mpeg4_configuration(nil), do: nil

  defp parse_mpeg4_configuration(doc) do
    xmap(
      doc,
      gov_length: ~x"./tt:GovLength/text()"i,
      mpeg4_profile: ~x"./tt:Mpeg4Profile/text()"s
    )
  end

  defp parse_h264_configuration([]), do: nil
  defp parse_h264_configuration(nil), do: nil

  defp parse_h264_configuration(doc) do
    xmap(
      doc,
      gov_length: ~x"./tt:GovLength/text()"i,
      h264_profile: ~x"./tt:H264Profile/text()"s
    )
  end

  defp rate_control_changeset(module, attrs) do
    cast(module, attrs, [:frame_rate_limit, :encoding_interval, :bitrate_limit])
  end

  defp mpeg4_configuration_changeset(module, attrs) do
    cast(module, attrs, [:gov_length, :mpeg4_profile])
  end

  defp h264_configuration_changeset(module, attrs) do
    cast(module, attrs, [:gov_length, :h264_profile])
  end
end
