defmodule ExOnvif.Media2.ServiceCapabilities do
  @moduledoc """
  Schema for the service capabilities of the ONVIF Media2 service.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import ExOnvif.Utils.Parser, only: [get_namespace_prefix: 2]
  import SweetXml

  @media2_namespace "http://www.onvif.org/ver20/media/wsdl"

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field :snapshot_uri, :boolean
    field :video_source_mode, :boolean
    field :rotation, :boolean
    field :osd, :boolean
    field :temporary_osd_text, :boolean
    field :mask, :boolean
    field :source_mask, :boolean
    field :web_rtc, :integer

    embeds_one :profile_capabilities, ProfileCapabilities, primary_key: false do
      @derive Jason.Encoder
      field :maximum_number_of_profiles, :integer
      field :configurations_supported, {:array, :string}
    end

    embeds_one :streaming_capabilities, StreamingCapabilities, primary_key: false do
      @derive Jason.Encoder
      field :rtsp_streaming, :boolean
      field :rtp_multicast, :boolean
      field :rtp_rtsp_tcp, :boolean
      field :non_aggregated_control, :boolean, default: false
      field :rtsp_web_socket_uri, :string
      field :auto_start_multicast, :boolean, default: false
      field :secure_rtsp_streaming, :boolean, default: false
    end

    field :media_signing_protocol, :boolean
  end

  def parse(doc) do
    ns = get_namespace_prefix(doc, @media2_namespace)

    xmap(doc,
      snapshot_uri: ~x"./@SnapshotUri"s,
      video_source_mode: ~x"./@VideoSourceMode"s,
      rotation: ~x"./@Rotation"s,
      osd: ~x"./@OSD"s,
      temporary_osd_text: ~x"./@TemporaryOSDText"s,
      mask: ~x"./@Mask"s,
      source_mask: ~x"./@SourceMask"s,
      web_rtc: ~x"./@WebRTC"s,
      media_signing_protocol:
        ~x"./#{ns}:MediaSignginCapabilities/#{ns}:MediaSigningProtocol/text()"s,
      profile_capabilities: [
        ~x"./#{ns}:ProfileCapabilities"e,
        maximum_number_of_profiles: ~x"./@MaximumNumberOfProfiles"s,
        configurations_supported:
          ~x"./@ConfigurationsSupported"so |> transform_by(&String.split(&1, " "))
      ],
      streaming_capabilities: [
        ~x"./#{ns}:StreamingCapabilities"e,
        rtsp_streaming: ~x"./@RTSPStreaming"s,
        rtp_multicast: ~x"./@RTPMulticast"s,
        rtp_rtsp_tcp: ~x"./@RTP_RTSP_TCP"s,
        non_aggregated_control: ~x"./@NonAggregatedControl"s,
        rtsp_web_socket_uri: ~x"./@RTSPWebSocketURI"s,
        auto_start_multicast: ~x"./@AutoStartMulticast"s,
        secure_rtsp_streaming: ~x"./@SecureRTSPStreaming"s
      ]
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :snapshot_uri,
      :video_source_mode,
      :rotation,
      :osd,
      :temporary_osd_text,
      :mask,
      :source_mask,
      :web_rtc,
      :media_signing_protocol
    ])
    |> cast_embed(:profile_capabilities, with: &profile_capabilities_changeset/2)
    |> cast_embed(:streaming_capabilities, with: &streaming_capabilities_changeset/2)
  end

  defp profile_capabilities_changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:maximum_number_of_profiles, :configurations_supported])
  end

  defp streaming_capabilities_changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :rtsp_streaming,
      :rtp_multicast,
      :rtp_rtsp_tcp,
      :non_aggregated_control,
      :rtsp_web_socket_uri,
      :auto_start_multicast,
      :secure_rtsp_streaming
    ])
  end
end
