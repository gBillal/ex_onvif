defmodule ExOnvif.Media.ServiceCapabilities do
  @moduledoc """
  Schema describing the capabilities of media service.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import SweetXml

  @required []
  @optional [
    :snapshot_uri,
    :rotation,
    :video_source_mode,
    :osd,
    :temporary_osd_text,
    :exi_compression,
    :maximum_number_of_profiles
  ]

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:snapshot_uri, :boolean, default: false)
    field(:rotation, :boolean, default: false)
    field(:video_source_mode, :boolean, default: false)
    field(:osd, :boolean, default: false)
    field(:temporary_osd_text, :boolean, default: false)
    field(:exi_compression, :boolean, default: false)
    field(:maximum_number_of_profiles, :integer)

    embeds_one :streaming_capabilities, StreamingCapabilities,
      primary_key: false,
      on_replace: :update do
      @derive Jason.Encoder
      field(:rtsp_multicast, :boolean, default: false)
      field(:rtp_tcp, :boolean, default: false)
      field(:rtp_rtsp_tcp, :boolean, default: false)
      field(:non_aggregated_control, :boolean, default: false)
      field(:no_rtsp_streaming, :boolean, default: false)
    end
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
    |> cast_embed(:streaming_capabilities,
      with: &streaming_capabilities_changeset/2
    )
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      snapshot_uri: ~x"./@SnapshotUri"so,
      rotation: ~x"./@Rotation"so,
      video_source_mode: ~x"./@VideoSourceMode"so,
      osd: ~x"./@OSD"so,
      temporary_osd_text: ~x"./@TemporaryOSDText"so,
      exi_compression: ~x"./@EXICompression"so,
      maximum_number_of_profiles: ~x"./trt:ProfileCapabilities/@MaximumNumberOfProfiles"so,
      streaming_capabilities:
        ~x"./trt:StreamingCapabilities"eo |> transform_by(&parse_streaming_capabilities/1)
    )
  end

  defp streaming_capabilities_changeset(module, attrs) do
    cast(module, attrs, [
      :rtsp_multicast,
      :rtp_tcp,
      :rtp_rtsp_tcp,
      :non_aggregated_control,
      :no_rtsp_streaming
    ])
  end

  defp parse_streaming_capabilities([]), do: nil
  defp parse_streaming_capabilities(nil), do: nil

  defp parse_streaming_capabilities(doc) do
    xmap(
      doc,
      rtsp_multicast: ~x"./@RTPMulticast "so,
      rtp_tcp: ~x"./@RTP_TCP"so,
      rtp_rtsp_tcp: ~x"./@RTP_RTSP_TCP"so,
      non_aggregated_control: ~x"./@NonAggregateControl"so,
      no_rtsp_streaming: ~x"./@NoRTSPStreaming"so
    )
  end
end
