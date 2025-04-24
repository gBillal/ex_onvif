defmodule Onvif.Media do
  @moduledoc """
  Interface for making requests to the 1.0 version of Onvif Media Service

  https://www.onvif.org/ver10/media/wsdl/media.wsdl
  """

  import Onvif.Utils.ApiClient, only: [media_request: 4]
  import Onvif.Utils.Parser
  import Onvif.Utils.XmlBuilder
  import SweetXml

  alias Onvif.Media.{
    AudioEncoderConfigurationOptions,
    OSD,
    OSDOptions,
    Profile,
    ServiceCapabilities,
    VideoEncoderConfigurationOptions
  }

  alias Onvif.Media.Profile.{AudioEncoderConfiguration, VideoEncoderConfiguration}

  @type encoder_options_opts :: [configuration_token: String.t(), profile_token: String.t()]

  @doc """
  Create the OSD.
  """
  @spec create_osd(Onvif.Device.t(), OSD.t()) :: {:ok, String.t()} | {:error, any()}
  def create_osd(device, osd) do
    body = element(:"trt:CreateOSD", OSD.encode(osd))
    media_request(device, "CreateOSD", body, &parse_create_osd_response/1)
  end

  @doc """
  Delete the OSD with the provided token.
  """
  @spec delete_osd(Onvif.Device.t(), String.t()) :: :ok | {:error, any()}
  def delete_osd(device, token) do
    body = element(:"trt:DeleteOSD", element(:"trt:OSDToken", token))
    media_request(device, "DeleteOSD", body, fn _body -> :ok end)
  end

  @doc """
  The GetAudioEncoderConfiguration command fetches the encoder configuration if the audio encoder configuration token is known.
  """
  @spec get_audio_encoder_configuration(Onvif.Device.t(), String.t()) ::
          {:ok, AudioEncoderConfiguration.t()} | {:error, any()}
  def get_audio_encoder_configuration(device, config_token) do
    body =
      element(
        :"trt:GetAudioEncoderConfiguration",
        element(:"trt:ConfigurationToken", config_token)
      )

    media_request(
      device,
      "GetAudioEncoderConfiguration",
      body,
      &parse_audio_encoder_configuration_response/1
    )
  end

  @doc """
  This operation returns the available options (supported values and ranges for audio encoder configuration parameters) when the audio encoder
  parameters are reconfigured.
  """
  @spec get_audio_configuration_options(Onvif.Device.t(), encoder_options_opts()) ::
          {:ok, AudioEncoderConfigurationOptions.t()} | {:error, any()}
  def get_audio_configuration_options(device, opts \\ []) do
    body =
      element(
        :"trt:GetAudioEncoderConfigurationOptions",
        element(:"trt:ConfigurationToken", opts[:configuration_token])
        |> element(:"trt:ProfileToken", opts[:profile_token])
      )

    media_request(
      device,
      "GetAudioEncoderConfigurationOptions",
      body,
      &parse_audio_encoder_configuration_options_response/1
    )
  end

  @doc """
  Get OSD by token.
  """
  @spec get_osd(Onvif.Device.t(), String.t()) :: {:ok, OSD.t()} | {:error, any()}
  def get_osd(device, token) do
    body = element(:"trt:GetOSD", element(:"trt:OSDToken", token))
    media_request(device, "GetOSD", body, &parse_osd_response/1)
  end

  @doc """
  Get the OSD Options.
  """
  @spec get_osd_options(Onvif.Device.t()) :: {:ok, OSDOptions.t()} | {:error, any()}
  @spec get_osd_options(Onvif.Device.t(), String.t() | nil) ::
          {:ok, OSDOptions.t()} | {:error, any()}
  def get_osd_options(device, token \\ nil) do
    body = element(:"trt:GetOSDOptions", element(:"trt:ConfigurationToken", token))
    media_request(device, "GetOSDOptions", body, &parse_osd_options_response/1)
  end

  @doc """
  Get the OSDs.
  """
  @spec get_osds(Onvif.Device.t()) :: {:ok, [OSD.t()]} | {:error, any()}
  @spec get_osds(Onvif.Device.t(), String.t() | nil) :: {:ok, [OSD.t()]} | {:error, any()}
  def get_osds(device, configuration_token \\ nil) do
    body = element(:"trt:GetOSDs", element(:"trt:ConfigurationToken", configuration_token))
    media_request(device, "GetOSDs", body, &parse_osds_response/1)
  end

  @doc """
  Get profile by token.
  """
  @spec get_profile(Onvif.Device.t(), String.t()) :: {:ok, Profile.t()} | {:error, any()}
  def get_profile(device, token) do
    body = element(:"trt:GetProfile", element(:"trt:ProfileToken", token))
    media_request(device, "GetProfile", body, &parse_profile_response/1)
  end

  @doc """
  Get existing media profiles of a device.

  Pre-configured or dynamically configured profiles can be retrieved using this command. This command lists all configured
  profiles in a device. The client does not need to know the media profile in order to use the command.
  """
  @spec get_profiles(Onvif.Device.t()) :: {:ok, [Profile.t()]} | {:error, any()}
  def get_profiles(device) do
    media_request(device, "GetProfiles", :"trt:GetProfiles", &parse_profiles_response/1)
  end

  @doc """
  Returns the capabilities of the media service.
  """
  @spec get_service_capabilities(Onvif.Device.t()) ::
          {:ok, ServiceCapabilities.t()} | {:error, any()}
  def get_service_capabilities(device) do
    media_request(
      device,
      "GetServiceCapabilities",
      :"trt:GetServiceCapabilities",
      &parse_service_capabilities_response/1
    )
  end

  @doc """
  A client uses the GetSnapshotUri command to obtain a JPEG snapshot from the device.

  The URI can be used for acquiring a JPEG image through a HTTP GET operation. The image encoding will always be JPEG regardless
  of the encoding setting in the media profile. The Jpeg settings (like resolution or quality) may be taken from the profile if suitable.
  """
  @spec get_snapshot_uri(Onvif.Device.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def get_snapshot_uri(device, profile_token) do
    body = element(:"trt:GetSnapshotUri", element(:"trt:ProfileToken", profile_token))
    media_request(device, "GetSnapshotUri", body, &parse_snapshot_uri_response/1)
  end

  @doc """
  This operation requests a URI that can be used to initiate a live media stream using RTSP as the control protocol.

  The correct syntax for the StreamSetup element for these media stream setups defined in 5.1.1 of the streaming specification are as follows:
    * RTP unicast over UDP: StreamType = "RTP_unicast", TransportProtocol = "UDP"
    * RTP over RTSP over HTTP over TCP: StreamType = "RTP_unicast", TransportProtocol = "HTTP"
    * RTP over RTSP over TCP: StreamType = "RTP_unicast", TransportProtocol = "RTSP"

  If a multicast stream is requested at least one of VideoEncoderConfiguration, AudioEncoderConfiguration and MetadataConfiguration shall have a valid
  multicast setting.
  """
  @spec get_stream_uri(Onvif.Device.t(), String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, any()}
  def get_stream_uri(device, profile_token, stream \\ "RTP-Unicast", transport_protocol \\ "UDP") do
    body =
      element(
        :"trt:GetStreamUri",
        element(:"trt:ProfileToken", profile_token)
        |> element(
          :"trt:StreamSetup",
          element(:"tt:Stream", stream)
          |> element(:"tt:Transport", element(:"tt:Protocol", transport_protocol))
        )
      )

    media_request(device, "GetStreamUri", body, &parse_stream_uri_response/1)
  end

  @doc """
  If the video encoder configuration token is already known, the encoder configuration can be fetched through the GetVideoEncoderConfiguration command.
  """
  @spec get_video_encoder_configuration(Onvif.Device.t(), String.t()) ::
          {:ok, VideoEncoderConfiguration.t()} | {:error, any()}
  def get_video_encoder_configuration(device, config_token) do
    body =
      element(
        :"trt:GetVideoEncoderConfiguration",
        element(:"trt:ConfigurationToken", config_token)
      )

    media_request(
      device,
      "GetVideoEncoderConfiguration",
      body,
      &parse_video_encoder_configuration_response/1
    )
  end

  @doc """
  This operation returns the available options (supported values and ranges for video encoder configuration parameters) when the video encoder parameters
  are reconfigured.

  For JPEG, MPEG4 and H264 extension elements have been defined that provide additional information. A device must provide the XxxOption information
  for all encodings supported and should additionally provide the corresponding XxxOption2 information.

  This response contains the available video encoder configuration options. If a video encoder configuration is specified,
  the options shall concern that particular configuration. If a media profile is specified, the options shall be compatible
  with that media profile. If no tokens are specified, the options shall be considered generic for the device.
  """
  @spec get_video_encoder_configuration_options(Onvif.Device.t(), encoder_options_opts()) ::
          {:ok, [VideoEncoderConfigurationOptions.t()]} | {:error, any()}
  def get_video_encoder_configuration_options(device, opts \\ []) do
    body =
      element(
        :"trt:GetVideoEncoderConfigurationOptions",
        element(:"trt:ConfigurationToken", opts[:configuration_token])
        |> element(:"trt:ProfileToken", opts[:profile_token])
      )

    media_request(
      device,
      "GetVideoEncoderConfigurationOptions",
      body,
      &parse_video_encoder_configuration_options_response/1
    )
  end

  @doc """
  This operation modifies an audio encoder configuration.

  The ForcePersistence flag indicates if the changes shall remain after reboot of the device. Running streams using this configuration may be immediately updated according to the new settings. The changes are not guaranteed to take effect unless the client requests a new stream URI and restarts any affected streams. NVC methods for changing a running stream are out of scope for this specification.
  """
  @spec set_audio_encoder_configuration(
          Onvif.Device.t(),
          AudioEncoderConfiguration.t()
        ) :: :ok | {:error, any()}
  def set_audio_encoder_configuration(device, encoder_config) do
    body =
      element(
        :"trt:SetAudioEncoderConfiguration",
        AudioEncoderConfiguration.encode(encoder_config, "tt:Configuration")
      )
      |> element("trt:ForcePeristence", true)

    media_request(device, "SetAudioEncoderConfiguration", body, fn _body -> :ok end)
  end

  @doc """
  Set the OSD
  """
  @spec set_osd(Onvif.Device.t(), OSD.t()) :: :ok | {:error, any()}
  def set_osd(device, osd) do
    body = element(:"trt:SetOSD", OSD.encode(osd))
    media_request(device, "SetOSD", body, fn _body -> :ok end)
  end

  @doc """
  This operation modifies a video encoder configuration.

  The ForcePersistence flag indicates if the changes shall remain after reboot of the device. Changes in the Multicast settings
  shall always be persistent. Running streams using this configuration may be immediately updated according to the new settings.
  The changes are not guaranteed to take effect unless the client requests a new stream URI and restarts any affected stream.
  NVC methods for changing a running stream are out of scope for this specification.

  SessionTimeout is provided as a hint for keeping rtsp session by a device. If necessary the device may adapt parameter
  values for SessionTimeout elements without returning an error. For the time between keep alive calls the client shall adhere
  to the timeout value signaled via RTSP.
  """
  @spec set_video_encoder_configuration(
          Onvif.Device.t(),
          VideoEncoderConfiguration.t()
        ) :: :ok | {:error, any()}
  def set_video_encoder_configuration(device, encoder_config) do
    body =
      element(
        :"trt:SetVideoEncoderConfiguration",
        VideoEncoderConfiguration.encode(encoder_config, "tt:Configuration")
      )

    media_request(device, "SetVideoEncoderConfiguration", body, fn _body -> :ok end)
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
    |> parse_map_reduce(Profile)
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
    |> parse_map_reduce(OSD)
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

  defp parse_stream_uri_response(xml_response_body) do
    uri =
      xml_response_body
      |> parse(namespace_conformant: true, quiet: true)
      |> xpath(
        ~x"//s:Envelope/s:Body/trt:GetStreamUriResponse/trt:MediaUri/tt:Uri/text()"s
        |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
        |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
        |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      )

    {:ok, uri}
  end

  defp parse_video_encoder_configuration_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/trt:GetVideoEncoderConfigurationResponse/trt:Configuration"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> VideoEncoderConfiguration.parse()
    |> VideoEncoderConfiguration.to_struct()
  end

  defp parse_video_encoder_configuration_options_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/trt:GetVideoEncoderConfigurationOptionsResponse/trt:Options"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> VideoEncoderConfigurationOptions.parse()
    |> VideoEncoderConfigurationOptions.to_struct()
  end

  defp parse_audio_encoder_configuration_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/trt:GetAudioEncoderConfigurationResponse/trt:Configuration"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> AudioEncoderConfiguration.parse()
    |> AudioEncoderConfiguration.to_struct()
  end

  defp parse_audio_encoder_configuration_options_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/trt:GetAudioEncoderConfigurationOptionsResponse/trt:Options"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("trt", "http://www.onvif.org/ver10/media/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> AudioEncoderConfigurationOptions.parse()
    |> AudioEncoderConfigurationOptions.to_struct()
  end
end
