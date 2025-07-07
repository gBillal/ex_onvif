defmodule ExOnvif.Media2Test do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias ExOnvif.Media.Profile.VideoSourceConfiguration
  alias ExOnvif.Media2.{ServiceCapabilities, VideoEncoderConfigurationOption}

  test "create profile" do
    xml_response = File.read!("test/fixtures/create_profile.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert {:ok, "profile1"} = ExOnvif.Media2.create_profile(device, "New Profile")
  end

  test "get service capabitiies" do
    xml_response = File.read!("test/fixtures/get_media2_service_capabilities.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = ExOnvif.Media2.get_service_capabilities(device)

    assert %ServiceCapabilities{
             snapshot_uri: true,
             video_source_mode: false,
             rotation: false,
             osd: true,
             temporary_osd_text: nil,
             mask: true,
             source_mask: nil,
             web_rtc: nil,
             profile_capabilities: %ServiceCapabilities.ProfileCapabilities{
               maximum_number_of_profiles: 8,
               configurations_supported: [
                 "VideoSource",
                 "VideoEncoder",
                 "AudioSource",
                 "AudioEncoder",
                 "AudioOutput",
                 "AudioDecoder",
                 "Metadata",
                 "Analytics"
               ]
             },
             streaming_capabilities: nil,
             media_signing_protocol: nil
           } == response

    assert {:ok, _json} = Jason.encode(response)
  end

  test "get video encoder configuration options" do
    xml_response = File.read!("test/fixtures/get_media2_video_encoder_configuration_options.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = ExOnvif.Media2.get_video_encoder_configuration_options(device)

    assert [
             %VideoEncoderConfigurationOption{
               bitrate_range: %ExOnvif.Schemas.IntRange{
                 max: 16384,
                 min: 32
               },
               constant_bit_rate_supported: true,
               encoding: :h264,
               frame_rates_supported: [
                 12.5,
                 12.0,
                 10.0,
                 8.0,
                 6.0,
                 4.0,
                 2.0,
                 1.0,
                 0.5,
                 0.25,
                 0.125,
                 0.0625
               ],
               gov_length_range: [1, 250],
               guaranteed_frame_rate_supported: nil,
               max_anchor_frame_distance: 0,
               profiles_supported: ["Main", "High"],
               quality_range: %ExOnvif.Schemas.FloatRange{
                 max: 5,
                 min: 0
               },
               resolutions_available: [
                 %ExOnvif.Media.VideoResolution{height: 720, width: 1280},
                 %ExOnvif.Media.VideoResolution{height: 2160, width: 3840}
               ]
             },
             %VideoEncoderConfigurationOption{
               bitrate_range: %ExOnvif.Schemas.IntRange{
                 max: 16384,
                 min: 32
               },
               constant_bit_rate_supported: true,
               encoding: :h265,
               frame_rates_supported: [
                 12.5,
                 12.0,
                 10.0,
                 8.0,
                 6.0,
                 4.0,
                 2.0,
                 1.0,
                 0.5,
                 0.25,
                 0.125,
                 0.0625
               ],
               gov_length_range: [1, 250],
               guaranteed_frame_rate_supported: nil,
               max_anchor_frame_distance: 0,
               profiles_supported: ["Main"],
               quality_range: %ExOnvif.Schemas.FloatRange{
                 max: 5,
                 min: 0
               },
               resolutions_available: [
                 %ExOnvif.Media.VideoResolution{height: 1080, width: 1920},
                 %ExOnvif.Media.VideoResolution{height: 1440, width: 2560},
                 %ExOnvif.Media.VideoResolution{height: 1728, width: 3072}
               ]
             }
           ] == response

    assert {:ok, _json} = Jason.encode(response)
  end

  test "get video source configurations" do
    xml_response = File.read!("test/fixtures/get_media2_video_source_configurations.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, [response]} = ExOnvif.Media2.get_video_source_configurations(device)

    assert %VideoSourceConfiguration{
             name: "user0",
             reference_token: "0",
             source_token: "0",
             use_count: 4,
             bounds: %VideoSourceConfiguration.Bounds{
               height: 2160,
               width: 3840,
               x: 0,
               y: 0
             }
           } == response
  end
end
