defmodule Onvif.Devices do
  @moduledoc """
  Interface for making requests to the Onvif devices service

  https://www.onvif.org/ver10/device/wsdl/devicemgmt.wsdl
  """
  require Logger

  import Onvif.ApiUtils, only: [devicemgmt_request: 4]
  import SweetXml
  import XmlBuilder

  alias Onvif.Devices.{
    DeviceInformation,
    HostnameInformation,
    NetworkProtocol,
    NetworkInterface,
    NTP,
    Scope,
    Service,
    ServiceCapabilities,
    SystemDateAndTime
  }

  @doc """
  This operation gets basic device information from the device.
  """
  @spec get_device_information(Onvif.Device.t()) :: {:ok, DeviceInformation.t()} | {:error, any()}
  def get_device_information(device) do
    body = element(:"s:Body", [element(:"tds:GetDeviceInformation")])

    devicemgmt_request(
      device,
      "GetDeviceInformation",
      body,
      &parse_device_information_response/1
    )
  end

  @doc """
  This operation is used by an endpoint to get the hostname from a device.
  """
  @spec get_hostname(Onvif.Device.t()) :: {:ok, HostnameInformation.t()} | {:error, any()}
  def get_hostname(device) do
    body = element(:"s:Body", [element(:"tds:GetHostname")])
    devicemgmt_request(device, "GetHostname", body, &parse_hostname_response/1)
  end

  @doc """
  This operation gets defined network protocols from a device.
  """
  @spec get_network_protocols(Onvif.Device.t()) :: {:ok, [NetworkProtocol.t()]} | {:error, any()}
  def get_network_protocols(device) do
    body = element(:"s:Body", [element(:"tds:GetNetworkProtocols")])

    devicemgmt_request(
      device,
      "GetNetworkProtocols",
      body,
      &parse_network_protocols_response/1
    )
  end

  @doc """
  This operation gets the network interface configuration from a device.
  """
  @spec get_network_interfaces(Onvif.Device.t()) ::
          {:ok, [NetworkInterface.t()]} | {:error, any()}
  def get_network_interfaces(device) do
    body = element(:"s:Body", [element(:"tds:GetNetworkInterfaces")])

    devicemgmt_request(
      device,
      "GetNetworkInterfaces",
      body,
      &parse_network_interfaces_response/1
    )
  end

  @doc """
  This operation gets the NTP settings from a device.
  """
  @spec get_ntp(Onvif.Device.t()) :: {:ok, NTP.t()} | {:error, any()}
  def get_ntp(device) do
    body = element(:"s:Body", [element(:"tds:GetNTP")])
    devicemgmt_request(device, "GetNTP", body, &parse_ntp_response/1)
  end

  @doc """
  This operation requests the scope parameters of a device.

  The scope parameters are used in the device discovery to match a probe message. The Scope parameters are of two different types:
    * Fixed
    * Configurable

  Fixed scope parameters are permanent device characteristics and cannot be removed through the device management interface.
  The scope type is indicated in the scope list returned in the get scope parameters response. A device shall support retrieval
  of discovery scope parameters through the GetScopes command.

  As some scope parameters are mandatory, the device shall return a non-empty scope list in the response.
  """
  @spec get_scopes(Onvif.Device.t()) :: {:ok, [Scope.t()]} | {:error, any()}
  def get_scopes(device) do
    body = element(:"s:Body", [element(:"tds:GetScopes")])
    devicemgmt_request(device, "GetScopes", body, &parse_scopes_response/1)
  end

  @doc """
  Returns the capabilities of the device service.
  """
  @spec get_service_capabilities(Onvif.Device.t()) ::
          {:ok, ServiceCapabilities.t()} | {:error, any()}
  def get_service_capabilities(device) do
    body = element(:"s:Body", [element(:"tds:GetServiceCapabilities")])

    devicemgmt_request(
      device,
      "GetServiceCapabilities",
      body,
      &parse_service_capabilities_response/1
    )
  end

  @doc """
  Returns information about services on the device.
  """
  @spec get_services(Onvif.Device.t()) :: {:ok, [Service.t()]} | {:error, any()}
  def get_services(device) do
    body =
      element(:"s:Body", [element(:"tds:GetServices", [element(:"tds:IncludeCapability", false)])])

    devicemgmt_request(device, "GetServices", body, &parse_services_response/1)
  end

  @doc """
  This operation gets the device system date and time. The device shall support the return of the daylight saving setting and of the manual
  system date and time (if applicable) or indication of NTP time (if applicable) through the GetSystemDateAndTime command.
  """
  @spec get_system_date_and_time(Onvif.Device.t()) ::
          {:ok, SystemDateAndTime.t()} | {:error, any()}
  def get_system_date_and_time(device) do
    body = element(:"s:Body", [element(:"tds:GetSystemDateAndTime")])
    updated_device = %{device | auth_type: :no_auth}

    devicemgmt_request(
      updated_device,
      "GetSystemDateAndTime",
      body,
      &parse_system_date_and_time_response/1
    )
  end

  @doc """
  This operation configures defined network protocols on a device.
  """
  @spec set_network_protocols(Onvif.Device.t(), NetworkProtocol.t() | [NetworkProtocol.t()]) ::
          :ok | {:error, any()}
  def set_network_protocols(device, network_protocols) do
    body =
      element(:"s:Body", [
        element(:"tds:SetNetworkProtocols", [
          network_protocols
          |> List.wrap()
          |> Enum.map(&NetworkProtocol.encode/1)
        ])
      ])

    devicemgmt_request(device, "SetNetworkProtocols", body, fn _body -> :ok end)
  end

  @doc """
  This operation sets the NTP settings on a device. If the device supports NTP, it shall be possible to set the NTP server settings through
  the SetNTP command.

  A device shall accept string formated according to RFC 1123 section 2.1 or alternatively to RFC 952, other string shall be considered
  as invalid strings.

  Changes to the NTP server list will not affect the clock mode DateTimeType. Use SetSystemDateAndTime to activate NTP operation.
  """
  @spec set_ntp(Onvif.Device.t(), NTP.t()) :: :ok | {:error, any()}
  def set_ntp(device, ntp) do
    body = element(:"s:Body", [element(:"tds:SetNTP", NTP.encode(ntp))])
    devicemgmt_request(device, "SetNTP", body, fn _body -> :ok end)
  end

  @doc """
  This operation sets the device system date and time. The device shall support the configuration of the daylight saving setting and of the manual
  system date and time (if applicable) or indication of NTP time (if applicable) through the SetSystemDateAndTime command.

  If system time and date are set manually, the client shall include UTCDateTime in the request.

  A TimeZone token which is not formed according to the rules of IEEE 1003.1 section 8.3 is considered as invalid timezone.

  The DayLightSavings flag should be set to true to activate any DST settings of the TimeZone string.
  Clear the DayLightSavings flag if the DST portion of the TimeZone settings should be ignored.
  """
  @spec set_system_date_and_time(Onvif.Device.t(), SystemDateAndTime.t()) :: :ok | {:error, any()}
  def set_system_date_and_time(device, date_and_time) do
    body = element(:"s:Body", [SystemDateAndTime.encode(date_and_time)])
    devicemgmt_request(device, "SetSystemDateAndTime", body, fn _body -> :ok end)
  end

  @doc """
  This operation reboots the device.
  """
  @spec system_reboot(Onvif.Device.t()) :: {:ok, %{message: String.t()}} | {:error, any()}
  def system_reboot(device) do
    body = element(:"s:Body", [element(:"tds:SystemReboot")])
    devicemgmt_request(device, "SystemReboot", body, &parse_system_reboot_response/1)
  end

  defp parse_device_information_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tds:GetDeviceInformationResponse"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tds", "http://www.onvif.org/ver10/device/wsdl")
    )
    |> DeviceInformation.parse()
    |> DeviceInformation.to_struct()
    |> case do
      {:ok, device_information} ->
        {:ok, device_information}

      {:error, changeset} ->
        Logger.error("Discarding invalid GetDeviceInformationResponse: #{inspect(changeset)}")
        {:ok, nil}
    end
  end

  defp parse_hostname_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tds:GetHostnameResponse/tds:HostnameInformation"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tds", "http://www.onvif.org/ver10/device/wsdl")
    )
    |> HostnameInformation.parse()
    |> HostnameInformation.to_struct()
  end

  defp parse_network_protocols_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tds:GetNetworkProtocolsResponse/tds:NetworkProtocols"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tds", "http://www.onvif.org/ver10/device/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> Enum.map(&NetworkProtocol.parse/1)
    |> Enum.reduce_while({:ok, []}, fn raw_config, {:ok, acc} ->
      case NetworkProtocol.to_struct(raw_config) do
        {:ok, config} -> {:cont, {:ok, [config | acc]}}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, network_protocols} -> {:ok, Enum.reverse(network_protocols)}
      other -> other
    end
  end

  defp parse_network_interfaces_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tds:GetNetworkInterfacesResponse/tds:NetworkInterfaces"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tds", "http://www.onvif.org/ver10/device/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> Enum.map(&NetworkInterface.parse/1)
    |> Enum.reduce_while({:ok, []}, fn raw_config, {:ok, acc} ->
      case NetworkInterface.to_struct(raw_config) do
        {:ok, config} -> {:cont, {:ok, [config | acc]}}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, network_interfaces} -> {:ok, Enum.reverse(network_interfaces)}
      other -> other
    end
  end

  defp parse_ntp_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tds:GetNTPResponse/tds:NTPInformation"eo
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tds", "http://www.onvif.org/ver10/device/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> NTP.parse()
    |> NTP.to_struct()
  end

  defp parse_scopes_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tds:GetScopesResponse/tds:Scopes"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tds", "http://www.onvif.org/ver10/device/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> Enum.map(&Scope.parse/1)
    |> Enum.reduce_while({:ok, []}, fn raw_scope, {:ok, acc} ->
      case Scope.to_struct(raw_scope) do
        {:ok, scope} -> {:cont, {:ok, [scope | acc]}}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, scopes} -> {:ok, Enum.reverse(scopes)}
      other -> other
    end
  end

  defp parse_service_capabilities_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tds:GetServiceCapabilitiesResponse/tds:Capabilities"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tds", "http://www.onvif.org/ver10/device/wsdl")
    )
    |> ServiceCapabilities.parse()
    |> ServiceCapabilities.to_struct()
  end

  defp parse_services_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tds:GetServicesResponse/tds:Service"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tds", "http://www.onvif.org/ver10/device/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> Enum.map(&Service.parse/1)
    |> Enum.reduce_while({:ok, []}, fn raw_service, {:ok, acc} ->
      case Service.to_struct(raw_service) do
        {:ok, service} -> {:cont, {:ok, [service | acc]}}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, services} -> {:ok, Enum.reverse(services)}
      other -> other
    end
  end

  defp parse_system_date_and_time_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tds:GetSystemDateAndTimeResponse/tds:SystemDateAndTime"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tds", "http://www.onvif.org/ver10/device/wsdl")
    )
    |> SystemDateAndTime.parse()
    |> SystemDateAndTime.to_struct()
  end

  defp parse_system_reboot_response(xml_response_body) do
    parsed_result =
      xml_response_body
      |> parse(namespace_conformant: true, quiet: true)
      |> xpath(
        ~x"//s:Envelope/s:Body/tds:SystemRebootResponse"
        |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
        |> add_namespace("tds", "http://www.onvif.org/ver10/device/wsdl"),
        message: ~x"./tds:Message/text()"s
      )

    {:ok, parsed_result}
  end
end
