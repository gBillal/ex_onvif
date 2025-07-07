defmodule ExOnvif.Replay.ServiceCapabilities do
  @moduledoc """
  Schema describing the capabilities of the Replay service.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field :reverse_playback, :boolean, default: false
    field :session_timeout_range, {:array, :float}
    field :rtp_rtsp_tcp, :boolean, default: false
    field :rtsp_web_socket_uri, :string
  end

  def parse(doc) do
    xmap(doc,
      reverse_playback: ~x"./@ReversePlayback"s,
      session_timeout_range: ~x"./@SessionTimeoutRange"s |> transform_by(&String.split(&1, " ")),
      rtp_rtsp_tcp: ~x"./@RTP_RTSP_TCP"s,
      rtsp_web_socket_uri: ~x"./@RTSPWebSocketURI"s
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(struct, params) do
    cast(struct, params, [
      :reverse_playback,
      :session_timeout_range,
      :rtp_rtsp_tcp,
      :rtsp_web_socket_uri
    ])
  end
end
