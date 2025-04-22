defmodule Onvif.SearchTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.Schemas.IntRange

  alias Onvif.Media.{
    OSDOptions,
    ServiceCapabilities,
    VideoEncoderConfigurationOptions,
    VideoResolution
  }

  alias Onvif.Media.OSD.{Color, ColorOptions}
  alias Onvif.Media.Ver10.Schemas.OSD

  test "create osd" do
    xml_response = File.read!("test/fixtures/create_osd.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, osdtoken} =
      Onvif.Media.create_osd(
        device,
        %OSD{
          image: nil,
          position: %OSD.Position{
            pos: %{x: "0.666000", y: "0.666000"},
            type: :custom
          },
          text_string: %OSD.TextString{
            background_color: nil,
            date_format: "MM/dd/yyyy",
            font_color: %Color{
              color: %{
                colorspace: "http://www.onvif.org/ver10/colorspace/YCbCr",
                x: "0.000000",
                y: "0.000000",
                z: "0.000000"
              },
              transparent: nil
            },
            font_size: 30,
            is_persistent_text: nil,
            plain_text: nil,
            time_format: "HH:mm:ss",
            type: :date_and_time
          },
          token: "",
          type: :text,
          video_source_configuration_token: "VideoSourceToken"
        }
      )

    assert osdtoken == "OsdToken_102"
  end

  test "delete osd" do
    xml_response = File.read!("test/fixtures/delete_osd.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert :ok = Onvif.Media.delete_osd(device, "token")
  end

  test "get osds" do
    xml_response = File.read!("test/fixtures/get_media_osds.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, osds} = Onvif.Media.get_osds(device)

    assert length(osds) == 2

    assert hd(osds) == %OSD{
             token: "OsdToken_101",
             video_source_configuration_token: "VideoSourceToken",
             type: :text,
             position: %OSD.Position{
               type: :custom,
               pos: %{x: "-1.000000", y: "0.866667"}
             },
             text_string: %OSD.TextString{
               is_persistent_text: nil,
               type: :date_and_time,
               date_format: "MM/dd/yyyy",
               time_format: "HH:mm:ss",
               font_size: 32,
               font_color: %Color{
                 transparent: nil,
                 color: %{
                   colorspace: "http://www.onvif.org/ver10/colorspace/YCbCr",
                   x: "0.000000",
                   y: "0.000000",
                   z: "0.000000"
                 }
               },
               background_color: nil,
               plain_text: nil
             },
             image: nil
           }
  end

  test "get osd options" do
    xml_response = File.read!("test/fixtures/get_osd_options.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, osdoptions} = Onvif.Media.get_osd_options(device, "token")

    assert osdoptions == %OSDOptions{
             image_option: nil,
             maximum_number_of_osds: %OSDOptions.MaximumNumberOfOSDs{
               date: 1,
               date_and_time: 1,
               image: 4,
               plaintext: 9,
               time: 1,
               total: 14
             },
             position_option: ["UpperLeft", "LowerLeft", "Custom"],
             text_option: %OSDOptions.TextOption{
               background_color: nil,
               date_format: ["MM/dd/yyyy", "dd/MM/yyyy", "yyyy/MM/dd", "yyyy-MM-dd"],
               font_color: %ColorOptions{
                 color: %ColorOptions.Color{
                   color_list: [],
                   color_space_range: %ColorOptions.Color.ColorSpaceRange{
                     color_space: "http://www.onvif.org/ver10/colorspace/YCbCr",
                     x: %Onvif.Schemas.FloatRange{min: 0.0, max: 255.0},
                     y: %Onvif.Schemas.FloatRange{min: 0.0, max: 255.0},
                     z: %Onvif.Schemas.FloatRange{min: 0.0, max: 255.0}
                   }
                 },
                 transparent: nil
               },
               font_size_range: %Onvif.Schemas.IntRange{
                 max: 64,
                 min: 16
               },
               time_format: ["hh:mm:ss tt", "HH:mm:ss"],
               type: ["Plain", "Date", "Time", "DateAndTime"]
             },
             type: ["Text"]
           }
  end

  test "get service capabilities" do
    xml_response = File.read!("test/fixtures/get_media_service_capabilities.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, service_capabilities} = Onvif.Media.get_service_capabilities(device)

    assert service_capabilities == %ServiceCapabilities{
             exi_compression: false,
             osd: true,
             maximum_number_of_profiles: 24,
             rotation: false,
             snapshot_uri: true,
             streaming_capabilities: %ServiceCapabilities.StreamingCapabilities{
               no_rtsp_streaming: false,
               non_aggregated_control: false,
               rtp_rtsp_tcp: true,
               rtp_tcp: false,
               rtsp_multicast: false
             },
             temporary_osd_text: false,
             video_source_mode: false
           }
  end

  test "get video encoder configuration options" do
    xml_response = File.read!("test/fixtures/get_video_encoder_configuration_options.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert {:ok, response} = Onvif.Media.get_video_encoder_configuration_options(device)

    assert %VideoEncoderConfigurationOptions{
             extension: nil,
             guranteed_frame_rate_supported: nil,
             h264: %VideoEncoderConfigurationOptions.H264Options{
               encoding_interval_range: %IntRange{max: 6, min: 1},
               frame_rate_range: %IntRange{max: 25, min: 1},
               gov_length_range: %IntRange{max: 150, min: 25},
               h264_profiles_supported: ["Baseline", "Main", "High"],
               resolutions_available: [
                 %VideoResolution{height: 576, width: 704},
                 %VideoResolution{height: 480, width: 640},
                 %VideoResolution{height: 288, width: 352}
               ]
             },
             jpeg: %VideoEncoderConfigurationOptions.JpegOptions{
               encoding_interval_range: %IntRange{max: 6, min: 1},
               frame_rate_range: %IntRange{max: 25, min: 1},
               resolutions_available: [
                 %VideoResolution{height: 576, width: 704},
                 %VideoResolution{height: 480, width: 640},
                 %VideoResolution{height: 288, width: 352}
               ]
             },
             mpeg4: nil,
             quality_range: %IntRange{max: 6, min: 1}
           } = response
  end

  test "set osd" do
    xml_response = File.read!("test/fixtures/set_osd_response.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert :ok =
             Onvif.Media.set_osd(
               device,
               %OSD{
                 image: nil,
                 position: %OSD.Position{
                   pos: %{x: "-1.000000", y: "0.866667"},
                   type: :custom
                 },
                 text_string: %OSD.TextString{
                   background_color: nil,
                   date_format: "MM/dd/yyyy",
                   font_color: %Color{
                     color: %{
                       colorspace: "http://www.onvif.org/ver10/colorspace/YCbCr",
                       x: "0.000000",
                       y: "0.000000",
                       z: "0.000000"
                     },
                     transparent: nil
                   },
                   font_size: 30,
                   is_persistent_text: nil,
                   plain_text: nil,
                   time_format: "HH:mm:ss",
                   type: :date_and_time
                 },
                 token: "OsdToken_101",
                 type: :text,
                 video_source_configuration_token: "VideoSourceToken"
               }
             )
  end
end
