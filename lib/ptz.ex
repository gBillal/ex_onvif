defmodule Onvif.PTZ do
  @moduledoc """
  Interface for making requests to the Onvif PTZ(Pan/Tilt/Zoom) service

  https://www.onvif.org/onvif/ver20/ptz/wsdl/ptz.wsdl
  """

  import Onvif.Utils.ApiClient, only: [ptz_request: 4]
  import Onvif.Utils.XmlBuilder
  import Onvif.Utils.Parser
  import SweetXml

  alias Onvif.PTZ.{Node, ServiceCapabilities, Status}

  @doc """
  Get the descriptions of the available PTZ Nodes.

  A PTZ-capable device may have multiple PTZ Nodes. The PTZ Nodes may represent mechanical PTZ drivers, uploaded PTZ drivers or digital PTZ drivers.
  PTZ Nodes are the lowest level entities in the PTZ control API and reflect the supported PTZ capabilities. The PTZ Node is referenced
  either by its name or by its reference token.
  """
  @spec get_nodes(Onvif.Device.t()) :: {:ok, [Node.t()]} | {:error, map()}
  def get_nodes(device) do
    body = element(:"s:Body", [:"tptz:GetNodes"])
    ptz_request(device, "GetNodes", body, &parse_nodes_response/1)
  end

  @doc """
  Returns the capabilities of the PTZ service.
  """
  @spec get_service_capabilities(Onvif.Device.t()) ::
          {:ok, ServiceCapabilities.t()} | {:error, any()}
  def get_service_capabilities(device) do
    body = element(:"s:Body", [:"tptz:GetServiceCapabilities"])
    ptz_request(device, "GetServiceCapabilities", body, &parse_service_capabilities/1)
  end

  @doc """
  Operation to request PTZ status for the Node in the selected profile.
  """
  @spec get_status(Onvif.Device.t(), String.t()) :: {:ok, Status.t()} | {:error, any()}
  def get_status(device, profile_token) do
    body =
      element("s:Body", element("tptz:GetStatus", element("tptz:ProfileToken", profile_token)))

    ptz_request(device, "GetStatus", body, &parse_status_response/1)
  end

  defp parse_nodes_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tptz:GetNodesResponse/tptz:PTZNode"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      |> add_namespace("tptz", "http://www.onvif.org/ver20/ptz/wsdl")
    )
    |> parse_map_reduce(Node)
  end

  defp parse_service_capabilities(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tptz:GetServiceCapabilitiesResponse/tptz:Capabilities"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      |> add_namespace("tptz", "http://www.onvif.org/ver20/ptz/wsdl")
    )
    |> ServiceCapabilities.parse()
    |> ServiceCapabilities.to_struct()
  end

  defp parse_status_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tptz:GetStatusResponse/tptz:PTZStatus"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      |> add_namespace("tptz", "http://www.onvif.org/ver20/ptz/wsdl")
    )
    |> Status.parse()
    |> Status.to_struct()
  end
end
