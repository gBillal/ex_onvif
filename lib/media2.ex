defmodule ExOnvif.Media2 do
  @moduledoc """
  Interface for making requests to the version 2.0 of Onvif Media Service

  https://www.onvif.org/ver20/media/wsdl/media.wsdl
  """

  import ExOnvif.Utils.ApiClient, only: [media2_request: 4]
  import ExOnvif.Utils.XmlBuilder
  import ExOnvif.Utils.Parser
  import SweetXml

  alias ExOnvif.Media.Profile.{
    AudioEncoderConfiguration,
    MetadataConfiguration,
    VideoSourceConfiguration
  }

  alias ExOnvif.Media2.{
    AddConfiguration,
    Profile,
    ServiceCapabilities,
    VideoEncoderConfigurationOption
  }

  alias ExOnvif.Media2.Profile.VideoEncoder

  @type encoder_options_opts :: [configuration_token: String.t(), profile_token: String.t()]

  @doc """
  This operation adds one or more Configurations to an existing media profile.

  If a configuration exists in the media profile, it will be replaced. A device shall support adding a compatible Configuration to a Profile
  containing a VideoSourceConfiguration and shall support streaming video data of such a profile.
  """
  @spec add_configuration(ExOnvif.Device.t(), AddConfiguration.t()) :: :ok | {:error, any()}
  def add_configuration(device, config) do
    body = AddConfiguration.encode(config)
    media2_request(device, "AddConfiguration", body, fn _body -> :ok end)
  end

  @doc """
  This operation creates a new media profile.

  A created profile created via this method may be deleted via the DeleteProfile method. Optionally Configurations
  can be assinged to the profile on creation. For details regarding profile assignement check also the method `add_configuration/2`.
  """
  @spec create_profile(
          ExOnvif.Device.t(),
          String.t(),
          [%{type: String.t(), token: String.t()}]
        ) :: {:ok, String.t()} | {:error, any()}
  def create_profile(device, name, configs \\ []) do
    configs =
      Enum.reduce(configs, [], fn config, acc ->
        acc
        |> element(
          "tr2:Configuration",
          element("tr2:Type", config.type)
          |> element("tr2:Token", config.token)
        )
      end)

    body = element("tr2:CreateProfile", element(configs, "tr2:Name", name))
    media2_request(device, "CreateProfile", body, &parse_create_profile/1)
  end

  @doc """
  By default this operation lists all existing audio encoder configurations for a device.

  Provide a profile token to list only configurations that are compatible with the profile. If a configuration
  token is provided only a single configuration will be returned.
  """
  @spec get_audio_encoder_configurations(Device.t(), encoder_options_opts()) ::
          {:ok, [AudioEncoderConfiguration.t()]} | {:error, any()}
  @spec get_audio_encoder_configurations(Device.t()) ::
          {:ok, [AudioEncoderConfiguration.t()]} | {:error, any()}
  def get_audio_encoder_configurations(device, opts \\ []) do
    body = encode_encoder_options("GetAudioEncoderConfigurations", opts)

    media2_request(
      device,
      "GetAudioEncoderConfigurations",
      body,
      &parse_get_audio_encoder_configurations_response/1
    )
  end

  @doc """
  By default this operation lists all existing metadata configurations for a device.

  Provide a profile token to list only configurations that are compatible with the profile. If a configuration token is provided only a single
  configuration will be returned.
  """
  @spec get_metadata_configurations(Device.t(), encoder_options_opts()) ::
          {:ok, [MetadataConfiguration.t()]} | {:error, any()}
  def get_metadata_configurations(device, opts \\ []) do
    body = encode_encoder_options("GetMetadataConfigurations", opts)

    media2_request(
      device,
      "GetMetadataConfigurations",
      body,
      &parse_get_metadata_configurations_response/1
    )
  end

  @doc """
  A client uses the GetSnapshotUri command to obtain a JPEG snapshot from the device.

  The returned URI shall remain valid indefinitely even if the profile is changed. The URI can be used for acquiring a JPEG image
  through an HTTP GET operation. The image encoding will always be JPEG regardless of the encoding setting in the media profile.
  The Jpeg settings (like resolution or quality) may be taken from the profile if suitable. The provided image will be updated automatically
  and independent from calls to GetSnapshotUri.
  """
  @spec get_snapshot_uri(Device.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def get_snapshot_uri(device, profile_token) do
    body = element("tr2:GetSnapshotUri", element("tr2:ProfileToken", profile_token))
    media2_request(device, "GetSnapshotUri", body, &parse_get_snapshot_uri_response/1)
  end

  @doc """
  This operation requests a URI that can be used to initiate a live media stream using RTSP as the control protocol.

  The returned URI shall remain valid indefinitely even if the profile is changed.

  Defined stream types are
    * RtspUnicast RTSP streaming RTP as UDP Unicast.
    * RtspMulticast RTSP streaming RTP as UDP Multicast.
    * RTSP RTSP streaming RTP over TCP.
    * RtspOverHttp Tunneling both the RTSP control channel and the RTP stream over HTTP or HTTPS.

  If a multicast stream is requested at least one of VideoEncoder2Configuration, AudioEncoder2Configuration and MetadataConfiguration
  shall have a valid multicast setting.
  """
  @spec get_stream_uri(ExOnvif.Device.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def get_stream_uri(device, profile_token) do
    body =
      element(
        "tr2:GetStreamUri",
        element("tr2:ProfileToken", profile_token) |> element("tr2:Protocol", "RTSP")
      )

    media2_request(device, "GetStreamUri", body, &parse_get_stream_uri_response/1)
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
        "tr2:GetProfiles",
        Enum.reduce(List.wrap(opts[:type] || "All"), [], &element(&2, "tr2:Type", &1))
        |> element("tr2:Token", opts[:token])
      )

    media2_request(device, "GetProfiles", body, &parse_get_profiles_response/1)
  end

  @doc """
  Returns the capabilities of the media service.
  """
  @spec get_service_capabilities(Device.t()) :: {:ok, ServiceCapabilities.t()} | {:error, any()}
  def get_service_capabilities(device) do
    body = element(:"tr2:GetServiceCapabilities")
    media2_request(device, "GetServiceCapabilities", body, &parse_service_capabilities/1)
  end

  @doc """
  This operation returns the available options (supported values and ranges for video encoder configuration parameters) when the video encoder
  parameters are reconfigured.

  This response contains the available video encoder configuration options. If a video encoder configuration is specified,
  the options shall concern that particular configuration. If a media profile is specified, the options shall be compatible with that media profile.
  If no tokens are specified, the options shall be considered generic for the device.
  """
  @spec get_video_encoder_configuration_options(
          Device.t(),
          encoder_options_opts()
        ) :: {:ok, [VideoEncoderConfigurationOption.t()]} | {:error, any()}
  def get_video_encoder_configuration_options(device, opts \\ []) do
    body = encode_encoder_options("GetVideoEncoderConfigurationOptions", opts)

    media2_request(
      device,
      "GetVideoEncoderConfigurationOptions",
      body,
      &parse_get_video_encoder_configuration_options_response/1
    )
  end

  @doc """
  By default this operation lists all existing video encoder configurations for a device.

  Provide a profile token to list only configurations that are compatible with the profile. If a configuration token
  is provided only a single configuration will be returned.
  """
  @spec get_video_encoder_configurations(
          ExOnvif.Device.t(),
          encoder_options_opts()
        ) :: {:ok, [VideoEncoderConfiguration.t()]} | {:error, any()}
  def get_video_encoder_configurations(device, opts \\ []) do
    body = encode_encoder_options("GetVideoEncoderConfigurations", opts)

    media2_request(
      device,
      "GetVideoEncoderConfigurations",
      body,
      &parse_get_video_encoder_configurations_response/1
    )
  end

  @doc """
  By default this operation lists all existing video source configurations for a device.

  Provide a profile token to list only configurations that are compatible with the profile. If a configuration token
  is provided only a single configuration will be returned.
  """
  @spec get_video_source_configurations(ExOnvif.Device.t()) ::
          {:ok, [VideoSourceConfiguration.t()]} | {:error, any()}
  @spec get_video_source_configurations(ExOnvif.Device.t(), encoder_options_opts()) ::
          {:ok, [VideoSourceConfiguration.t()]} | {:error, any()}
  def get_video_source_configurations(device, opts \\ []) do
    body = encode_encoder_options("GetVideoSourceConfigurations", opts)

    media2_request(
      device,
      "GetVideoSourceConfigurations",
      body,
      &parse_video_source_configurations_response/1
    )
  end

  @doc """
  This operation modifies an audio encoder configuration.

  Running streams using this configuration may be immediately updated according to the new settings. The changes are not guaranteed
  to take effect unless the client requests a new stream URI and restarts any affected streams.
  """
  @spec set_audio_encoder_configuration(
          ExOnvif.Device.t(),
          AudioEncoderConfiguration.t()
        ) :: :ok | {:error, any()}
  def set_audio_encoder_configuration(device, audio_configuration) do
    body =
      element(
        "tr2:SetAudioEncoderConfiguration",
        AudioEncoderConfiguration.encode(audio_configuration, "tr2:Configuration")
      )

    media2_request(device, "SetAudioEncoderConfiguration", body, fn _body -> :ok end)
  end

  @doc """
  This operation modifies a video encoder configuration.

  Running streams using this configuration may be immediately updated according to the new settings. The changes are not guaranteed to take
  effect unless the client requests a new stream URI and restarts any affected stream.

  SessionTimeout is provided as a hint for keeping rtsp session by a device. If necessary the device may adapt
  parameter values for SessionTimeout elements without returning an error. For the time between keep alive calls the client
  shall adhere to the timeout value signaled via RTSP.
  """
  @spec set_video_encoder_configuration(ExOnvif.Device.t(), VideoEncoder.t()) ::
          :ok | {:error, any()}
  def set_video_encoder_configuration(device, video_configuration) do
    body = element("tr2:SetVideoEncoderConfiguration", VideoEncoder.encode(video_configuration))
    media2_request(device, "SetVideoEncoderConfiguration", body, fn _body -> :ok end)
  end

  defp encode_encoder_options(operation, opts) do
    element(
      "tr2:#{operation}",
      element("tr2:ConfigurationToken", opts[:configuration_token])
      |> element("tr2:ProfileToken", opts[:profile_token])
    )
  end

  defp parse_create_profile(xml_response_body) do
    token =
      xml_response_body
      |> parse(namespace_conformant: true, quiet: true)
      |> xpath(
        ~x"//s:Envelope/s:Body/tr2:CreateProfileResponse/tr2:Token/text()"s
        |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
        |> add_namespace("tr2", "http://www.onvif.org/ver20/media/wsdl")
        |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      )

    {:ok, token}
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
    |> parse_map_reduce(AudioEncoderConfiguration)
  end

  defp parse_get_metadata_configurations_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tr2:GetMetadataConfigurationsResponse/tr2:Configurations"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tr2", "http://www.onvif.org/ver20/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> parse_map_reduce(MetadataConfiguration)
  end

  defp parse_get_snapshot_uri_response(xml_response_body) do
    uri =
      xml_response_body
      |> parse(namespace_conformant: true, quiet: true)
      |> xpath(
        ~x"//s:Envelope/s:Body/tr2:GetSnapshotUriResponse/tr2:Uri/text()"s
        |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
        |> add_namespace("tr2", "http://www.onvif.org/ver20/media/wsdl")
      )

    {:ok, uri}
  end

  defp parse_get_stream_uri_response(xml_response_body) do
    uri =
      xml_response_body
      |> parse(namespace_conformant: true, quiet: true)
      |> xpath(
        ~x"//s:Envelope/s:Body/tr2:GetStreamUriResponse/tr2:Uri/text()"s
        |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
        |> add_namespace("tr2", "http://www.onvif.org/ver20/media/wsdl")
      )

    {:ok, uri}
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
    |> parse_map_reduce(Profile)
  end

  defp parse_get_video_encoder_configurations_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tr2:GetVideoEncoderConfigurationsResponse/tr2:Configurations"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tr2", "http://www.onvif.org/ver20/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> parse_map_reduce(VideoEncoder)
  end

  defp parse_get_video_encoder_configuration_options_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tr2:GetVideoEncoderConfigurationOptionsResponse/tr2:Options"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tr2", "http://www.onvif.org/ver20/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> parse_map_reduce(VideoEncoderConfigurationOption)
  end

  defp parse_service_capabilities(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tr2:GetServiceCapabilitiesResponse/tr2:Capabilities"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tr2", "http://www.onvif.org/ver20/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> ServiceCapabilities.parse()
    |> ServiceCapabilities.to_struct()
  end

  defp parse_video_source_configurations_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tr2:GetVideoSourceConfigurationsResponse/tr2:Configurations"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tr2", "http://www.onvif.org/ver20/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> parse_map_reduce(VideoSourceConfiguration)
  end
end
