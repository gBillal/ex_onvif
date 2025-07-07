defmodule ExOnvif.Replay do
  @moduledoc """
  Interface for making requests to the Onvif replay service

  https://www.onvif.org/ver10/replay.wsdl
  """

  import ExOnvif.Utils.ApiClient, only: [replay_request: 4]
  import ExOnvif.Utils.XmlBuilder
  import SweetXml

  alias ExOnvif.Replay.ServiceCapabilities

  @doc """
  Requests a URI that can be used to initiate playback of a recorded stream using RTSP as the control protocol.

  The URI is valid only as it is specified in the response.
  """
  @spec get_replay_uri(ExOnvif.Device.t(), String.t(), stream: String.t(), protocol: String.t()) ::
          {:ok, String.t()} | {:error, any()}
  def get_replay_uri(device, recording_token, opts \\ []) do
    body =
      element(
        "trp:GetReplayUri",
        element("trp:RecordingToken", recording_token)
        |> element(
          "trp:StreamSetup",
          element("tt:Stream", Keyword.get(opts, :stream, "RTP-Unicast"))
          |> element(
            "tt:Transport",
            element("tt:Protocol", Keyword.get(opts, :protocol, "RTSP"))
          )
        )
      )

    replay_request(device, "GetReplayUri", body, &parse_replay_uri/1)
  end

  @doc """
  Returns the capabilities of the replay service.
  """
  @spec get_service_capabilities(ExOnvif.Device.t()) ::
          {:ok, ServiceCapabilities.t()} | {:error, any()}
  def get_service_capabilities(device) do
    body = element(:"trp:GetServiceCapabilities")
    replay_request(device, "GetServiceCapabilities", body, &parse_service_capabilities/1)
  end

  defp parse_replay_uri(xml_response_body) do
    uri =
      xml_response_body
      |> parse(namespace_conformant: true, quiet: true)
      |> xpath(
        ~x"//s:Envelope/s:Body/trp:GetReplayUriResponse/trp:Uri/text()"s
        |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
        |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
        |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      )

    {:ok, uri}
  end

  defp parse_service_capabilities(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/trp:GetServiceCapabilitiesResponse/trp:Capabilities"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> ServiceCapabilities.parse()
    |> ServiceCapabilities.to_struct()
  end
end
