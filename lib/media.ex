defmodule Onvif.Media do
  @moduledoc """
  Interface for making requests to the 1.0 version of Onvif Media Service

  https://www.onvif.org/ver10/media/wsdl/media.wsdl
  """

  import Onvif.Utils.ApiClient, only: [media_request: 4]
  import Onvif.Utils.XmlBuilder
  import SweetXml

  alias Onvif.Media.Ver10.Schemas.{OSD, Profile}

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
  Get existing media profiles of a device.

  Pre-configured or dynamically configured profiles can be retrieved using this command. This command lists all configured
  profiles in a device. The client does not need to know the media profile in order to use the command.
  """
  @spec get_profiles(Onvif.Device.t()) :: {:ok, [Profile.t()]} | {:error, any()}
  def get_profiles(device) do
    body = element(:"s:Body", [element(:"trt:GetProfiles")])
    media_request(device, "GetProfiles", body, &parse_profiles_response/1)
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
end
