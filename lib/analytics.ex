defmodule Onvif.Analytics do
  @moduledoc """
  Interface for making requests to the Onvif analytics service

  https://www.onvif.org/ver20/analytics/wsdl/analytics.wsdl
  """

  import Onvif.Utils.ApiClient, only: [analytics_request: 4]
  import SweetXml

  alias Onvif.Analytics.ServiceCapabilities

  @doc """
  Returns the capabilities of the analytics service.
  """
  @spec get_service_capabilities(Onvif.Device.t()) ::
          {:ok, ServiceCapabilities.t()} | {:error, any()}
  def get_service_capabilities(device) do
    analytics_request(
      device,
      "GetServiceCapabilities",
      :"axt:GetServiceCapabilities",
      &parse_service_capabilities/1
    )
  end

  defp parse_service_capabilities(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/axt:GetServiceCapabilitiesResponse/axt:Capabilities"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("axt", "http://www.onvif.org/ver20/analytics/wsdl")
    )
    |> ServiceCapabilities.parse()
    |> ServiceCapabilities.to_struct()
  end
end
