defmodule Onvif.Media2 do
  @moduledoc """
  Interface for making requests to the version 2.0 of Onvif Media Service

  https://www.onvif.org/ver20/media/wsdl/media.wsdl
  """

  import Onvif.Utils.ApiClient, only: [media2_request: 4]
  import Onvif.Utils.XmlBuilder
  import SweetXml

  alias Onvif.Media.Profile.AudioEncoderConfiguration
  alias Onvif.Media2.Profile

  @type encoder_options_opts :: [configuration_token: String.t(), profile_token: String.t()]

  @doc """
  By default this operation lists all existing audio encoder configurations for a device.

  Provide a profile token to list only configurations that are compatible with the profile. If a configuration
  token is provided only a single configuration will be returned.
  """
  @spec get_audio_encoder_configurations(Device.t(), encoder_options_opts()) ::
          {:ok, [AudioEncoderConfiguration.t()]} | {:error, any()}
  def get_audio_encoder_configurations(device, opts \\ []) do
    body =
      element(
        "s:Body",
        element(
          "tr2:GetAudioEncoderConfigurations",
          element("tr2:ConfigurationToken", opts[:configuration_token])
          |> element("tr2:ProfileToken", opts[:profile_token])
        )
      )

    media2_request(
      device,
      "GetAudioEncoderConfigurations",
      body,
      &parse_get_audio_encoder_configurations_response/1
    )
  end

  @doc """
  Retrieve the profile with the specified token or all defined media profiles.

    * If no Type is provided the returned profiles shall contain no configuration information.
    * If a single Type with value 'All' is provided the returned profiles shall include all associated configurations.
    * Otherwise the requested list of configurations shall for each profile include the configurations present as Type.
  """
  @spec get_profiles(Device.t(), token: String.t(), type: [String.t()]) ::
          {:ok, [Profile.t()]} | {:error, map()}
  def get_profiles(device, opts \\ []) do
    body =
      element(
        "s:Body",
        element(
          "tr2:GetProfiles",
          Enum.reduce(List.wrap(opts[:type] || "All"), [], &element(&2, "tr2:Type", &1))
          |> element("tr2:Token", opts[:token])
        )
      )

    media2_request(device, "GetProfiles", body, &parse_get_profiles_response/1)
  end

  defp parse_get_audio_encoder_configurations_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tr2:GetAudioEncoderConfigurationsResponse/tr2:Configurations"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tr2", "http://www.onvif.org/ver20/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> Enum.map(&AudioEncoderConfiguration.parse/1)
    |> Enum.reduce_while([], fn raw_config, acc ->
      case AudioEncoderConfiguration.to_struct(raw_config) do
        {:ok, config} -> {:cont, [config | acc]}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:error, _reason} = err -> err
      configs -> {:ok, Enum.reverse(configs)}
    end
  end

  defp parse_get_profiles_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tr2:GetProfilesResponse/tr2:Profiles"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tr2", "http://www.onvif.org/ver20/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> Enum.map(&Profile.parse/1)
    |> Enum.reduce_while([], fn raw_profile, acc ->
      case Profile.to_struct(raw_profile) do
        {:ok, profile} -> {:cont, [profile | acc]}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:error, _reason} = err -> err
      profiles -> {:ok, Enum.reverse(profiles)}
    end
  end
end
