defmodule Onvif.ReplayTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.Replay.ServiceCapabilities

  test "get replay uri" do
    xml_response = File.read!("test/fixtures/get_replay_uri.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert {:ok, response} =
             Onvif.Replay.get_replay_uri(device, "SD_DISK_20200422_132655_67086B52")

    assert response ==
             "rtsp://192.168.1.136/onvif-media/record/play.amp?onvifreplayid=SD_DISK_20200422_132655_67086B52&onvifreplayext=1&streamtype=unicast&session_timeout=30"
  end

  test "get service capabitiies" do
    xml_response = File.read!("test/fixtures/get_replay_service_capabilities.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = Onvif.Replay.get_service_capabilities(device)

    assert %ServiceCapabilities{
             reverse_playback: false,
             rtp_rtsp_tcp: true,
             session_timeout_range: [0.0, 4_294_967_295.0],
             rtsp_web_socket_uri: nil
           } == response

    assert {:ok, _json} = Jason.encode(response)
  end
end
