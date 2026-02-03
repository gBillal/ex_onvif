defmodule ExOnvif.PTZ do
  @moduledoc """
  Interface for making requests to the Onvif PTZ(Pan/Tilt/Zoom) service

  https://www.onvif.org/onvif/ver20/ptz/wsdl/ptz.wsdl
  """

  import ExOnvif.Utils.ApiClient, only: [ptz_request: 4]
  import ExOnvif.Utils.XmlBuilder
  import ExOnvif.Utils.Parser
  import SweetXml

  alias ExOnvif.PTZ.{AbsoluteMove, Node, ServiceCapabilities, Status}

  @doc """
  Operation to move pan,tilt or zoom to a absolute destination.

  The speed argument is optional. If an x/y speed value is given it is up to the device to either use the x value as absolute resoluting
  speed vector or to map x and y to the component speed. If the speed argument is omitted, the default speed set by the
  PTZConfiguration will be used.
  """
  @spec absolute_move(ExOnvif.Device.t(), AbsoluteMove.t()) :: :ok | {:error, any()}
  def absolute_move(device, abs_move) do
    body = AbsoluteMove.encode(abs_move)
    ptz_request(device, "AbsoluteMove", body, fn _body -> :ok end)
  end

  @doc """
  Get a specific PTZ Node identified by a reference token or a name.
  """
  @spec get_node(ExOnvif.Device.t(), String.t()) :: {:ok, Node.t()} | {:error, any()}
  def get_node(device, node_token) do
    body = element("tptz:GetNode", element("tptz:NodeToken", node_token))
    ptz_request(device, "GetNode", body, &parse_node_response/1)
  end

  @doc """
  Get the descriptions of the available PTZ Nodes.

  A PTZ-capable device may have multiple PTZ Nodes. The PTZ Nodes may represent mechanical PTZ drivers, uploaded PTZ drivers or digital PTZ drivers.
  PTZ Nodes are the lowest level entities in the PTZ control API and reflect the supported PTZ capabilities. The PTZ Node is referenced
  either by its name or by its reference token.
  """
  @spec get_nodes(ExOnvif.Device.t()) :: {:ok, [Node.t()]} | {:error, map()}
  def get_nodes(device) do
    ptz_request(device, "GetNodes", :"tptz:GetNodes", &parse_nodes_response/1)
  end

  @doc """
  Returns the capabilities of the PTZ service.
  """
  @spec get_service_capabilities(ExOnvif.Device.t()) ::
          {:ok, ServiceCapabilities.t()} | {:error, any()}
  def get_service_capabilities(device) do
    body = :"tptz:GetServiceCapabilities"
    ptz_request(device, "GetServiceCapabilities", body, &parse_service_capabilities/1)
  end

  @doc """
  Returns the the PTZconfigurations
  Get all the existing PTZConfigurations from the device.

  The default Position/Translation/Velocity Spaces are introduced to allow NVCs sending move requests without the need to specify a
  certain coordinate system. The default Speeds are introduced to control the speed of move requests (absolute, relative, preset),
  where no explicit speed has been set.

  """
  def get_configurations(device, profile_token) do
    body = element("tptz:GetConfigurations", element("tptz:ProfileToken", profile_token))
    ptz_request(device, "GetConfigurations", body, &parse_configuration_response/1)
  end

  @doc """
  Operation to request PTZ status for the Node in the selected profile.
  """
  @spec get_status(ExOnvif.Device.t(), String.t()) :: {:ok, Status.t()} | {:error, any()}
  def get_status(device, profile_token) do
    body = element("tptz:GetStatus", element("tptz:ProfileToken", profile_token))
    ptz_request(device, "GetStatus", body, &parse_status_response/1)
  end

  defp parse_configuration_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tptz:GetConfigurationsResponse/tptz:PTZConfiguration"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      |> add_namespace("tptz", "http://www.onvif.org/ver20/ptz/wsdl")
    )
    |> ExOnvif.PTZ.PTZConfigurations.parse()
    |> ExOnvif.PTZ.PTZConfigurations.to_struct()
  end

  defp parse_node_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tptz:GetNodeResponse/tptz:PTZNode"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      |> add_namespace("tptz", "http://www.onvif.org/ver20/ptz/wsdl")
    )
    |> Node.parse()
    |> Node.to_struct()
  end

  defp parse_nodes_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tptz:GetConfigurationResponse/tptz:PTZNode"el
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
