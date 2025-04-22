defmodule Onvif.Media do
  @moduledoc """
  Interface for making requests to the 1.0 version of Onvif Media Service

  https://www.onvif.org/ver10/media/wsdl/media.wsdl
  """

  import Onvif.Utils.ApiClient, only: [media_request: 4]
  import Onvif.Utils.XmlBuilder
  import SweetXml

  alias Onvif.Media.{OSDOptions, ServiceCapabilities}
  alias Onvif.Media.Ver10.Schemas.{OSD, Profile}

  @doc """
  Create the OSD.
  """
  @spec create_osd(Onvif.Device.t(), OSD.t()) :: {:ok, String.t()} | {:error, any()}
  def create_osd(device, osd) do
    body = element(:"s:Body", element(:"trt:CreateOSD", OSD.encode(osd)))
    media_request(device, "CreateOSD", body, &parse_create_osd_response/1)
  end

  @doc """
  Delete the OSD with the provided token.
  """
  @spec delete_osd(Onvif.Device.t(), String.t()) :: :ok | {:error, any()}
  def delete_osd(device, token) do
    body = element(:"s:Body", element(:"trt:DeleteOSD", element(:"trt:OSDToken", token)))
    media_request(device, "DeleteOSD", body, fn _body -> :ok end)
  end

  @doc """
  Get OSD by token.
  """
  @spec get_osd(Onvif.Device.t(), String.t()) :: {:ok, OSD.t()} | {:error, any()}
  def get_osd(device, token) do
    body = element(:"s:Body", element(:"trt:GetOSD", element(:"trt:OSDToken", token)))
    media_request(device, "GetOSD", body, &parse_osd_response/1)
  end

  @doc """
  Get the OSD Options.
  """
  @spec get_osd_options(Onvif.Device.t()) :: {:ok, OSDOptions.t()} | {:error, any()}
  @spec get_osd_options(Onvif.Device.t(), String.t() | nil) ::
          {:ok, OSDOptions.t()} | {:error, any()}
  def get_osd_options(device, token \\ nil) do
    body =
      element(:"s:Body", [
        element(:"trt:GetOSDOptions", element(:"trt:ConfigurationToken", token))
      ])

    media_request(device, "GetOSDOptions", body, &parse_osd_options_response/1)
  end

  @doc """
  Get the OSDs.
  """
  @spec get_osds(Onvif.Device.t()) :: {:ok, [OSD.t()]} | {:error, any()}
  @spec get_osds(Onvif.Device.t(), String.t() | nil) :: {:ok, [OSD.t()]} | {:error, any()}
  def get_osds(device, configuration_token \\ nil) do
    body =
      element(:"s:Body", [
        element(:"trt:GetOSDs", element(:"trt:ConfigurationToken", configuration_token))
      ])

    media_request(device, "GetOSDs", body, &parse_osds_response/1)
  end

  @doc """
  Get profile by token.
  """
  @spec get_profile(Onvif.Device.t(), String.t()) :: {:ok, Profile.t()} | {:error, any()}
  def get_profile(device, token) do
    body = element(:"s:Body", element(:"trt:GetProfile", element(:"trt:ProfileToken", token)))
    media_request(device, "GetProfile", body, &parse_profile_response/1)
  end

  @doc """
  Get existing media profiles of a device.

  Pre-configured or dynamically configured profiles can be retrieved using this command. This command lists all configured
  profiles in a device. The client does not need to know the media profile in order to use the command.
  """
  @spec get_profiles(Onvif.Device.t()) :: {:ok, [Profile.t()]} | {:error, any()}
  def get_profiles(device) do
    body = element(:"s:Body", [element(:"trt:GetProfiles")])
    media_request(device, "GetProfiles", body, &parse_profiles_response/1)
  end

  @doc """
  Returns the capabilities of the media service.
  """
  @spec get_service_capabilities(Onvif.Device.t()) ::
          {:ok, ServiceCapabilities.t()} | {:error, any()}
  def get_service_capabilities(device) do
    body = element(:"s:Body", [element(:"trt:GetServiceCapabilities")])
    media_request(device, "GetServiceCapabilities", body, &parse_service_capabilities_response/1)
  end

  @doc """
  A client uses the GetSnapshotUri command to obtain a JPEG snapshot from the device.

  The URI can be used for acquiring a JPEG image through a HTTP GET operation. The image encoding will always be JPEG regardless
  of the encoding setting in the media profile. The Jpeg settings (like resolution or quality) may be taken from the profile if suitable.
  """
  @spec get_snapshot_uri(Onvif.Device.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def get_snapshot_uri(device, profile_token) do
    body =
      element(
        :"s:Body",
        element(:"trt:GetSnapshotUri", element(:"trt:ProfileToken", profile_token))
      )

    media_request(device, "GetSnapshotUri", body, &parse_snapshot_uri_response/1)
  end

  defp parse_create_osd_response(xml_response_body) do
    token =
      xml_response_body
      |> parse(namespace_conformant: true, quiet: true)
      |> xpath(
        ~x"//s:Envelope/s:Body/trt:CreateOSDResponse/trt:OSDToken/text()"s
        |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
        |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
        |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      )

    {:ok, token}
  end

  defp parse_profile_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/trt:GetProfileResponse/trt:Profile"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> Profile.parse()
    |> Profile.to_struct()
  end

  defp parse_profiles_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/trt:GetProfilesResponse/trt:Profiles"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> Enum.map(&Profile.parse/1)
    |> Enum.reduce_while([], fn raw_profile, acc ->
      case Profile.to_struct(raw_profile) do
        {:ok, profile} -> {:cont, [profile | acc]}
        err -> {:halt, err}
      end
    end)
    |> case do
      {:error, _reason} = err -> err
      profiles -> {:ok, Enum.reverse(profiles)}
    end
  end

  defp parse_osd_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/trt:GetOSDResponse/trt:OSD"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> OSD.parse()
    |> OSD.to_struct()
  end

  defp parse_osd_options_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/trt:GetOSDOptionsResponse/trt:OSDOptions"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> OSDOptions.parse()
    |> OSDOptions.to_struct()
  end

  defp parse_osds_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/trt:GetOSDsResponse/trt:OSDs"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> Enum.map(&OSD.parse/1)
    |> Enum.reduce_while([], fn raw_osd, acc ->
      case OSD.to_struct(raw_osd) do
        {:ok, osd} -> {:cont, [osd | acc]}
        err -> {:halt, err}
      end
    end)
    |> case do
      {:error, _reason} = err -> err
      osds -> {:ok, Enum.reverse(osds)}
    end
  end

  defp parse_service_capabilities_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/trt:GetServiceCapabilitiesResponse/trt:Capabilities"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> ServiceCapabilities.parse()
    |> ServiceCapabilities.to_struct()
  end

  defp parse_snapshot_uri_response(xml_response_body) do
    uri =
      xml_response_body
      |> parse(namespace_conformant: true, quiet: true)
      |> xpath(
        ~x"//s:Envelope/s:Body/trt:GetSnapshotUriResponse/trt:MediaUri/tt:Uri/text()"s
        |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
        |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
        |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      )

    {:ok, uri}
  end
end
