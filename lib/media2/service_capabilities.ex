defmodule ExOnvif.Media2.ServiceCapabilities do
  @moduledoc """
  Schema for the service capabilities of the ONVIF Media2 service.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

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
      field :non_aggregated_control, :boolean
      field :rtsp_web_socket_uri, :string
      field :auto_start_multicast, :boolean
      field :secure_rtsp_streaming, :boolean
    end

    field :media_signing_protocol, :boolean
  end

  def parse(doc) do
    xmap(doc,
      snapshot_uri: ~x"./@SnapshotUri"s,
      video_source_mode: ~x"./@VideoSourceMode"s,
      rotation: ~x"./@Rotation"s,
      osd: ~x"./@OSD"s,
      temporary_osd_text: ~x"./@TemporaryOSDText"s,
      mask: ~x"./@Mask"s,
      source_mask: ~x"./@SourceMask"s,
      web_rtc: ~x"./@WebRTC"s,
      media_signing_protocol: ~x"./tr2:MediaSignginCapabilities/tr2:MediaSigningProtocol/text()"s,
      profile_capabilities: [
        ~x"./tr2:ProfileCapabilities"e,
        maximum_number_of_profiles: ~x"./@MaximumNumberOfProfiles"s,
        configurations_supported:
          ~x"./@ConfigurationsSupported"so |> transform_by(&String.split(&1, " "))
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
