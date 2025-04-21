defmodule Onvif.SearchTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.Media.Ver10.Schemas.OSD

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
               font_color: %OSD.TextString.FontColor{
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
end
