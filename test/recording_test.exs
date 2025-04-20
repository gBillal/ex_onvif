defmodule Onvif.DevicesTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.Recording.Schemas.{
    Recording
  }

  test "get recordings" do
    xml_response = File.read!("test/fixtures/get_recordings.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = Onvif.Recording2.get_recordings(device)

    assert Enum.map(response, & &1.recording_token) == [
             "SD_DISK_20200422_123501_A2388AB3",
             "SD_DISK_20200422_132613_45A883F5",
             "SD_DISK_20200422_132655_67086B52"
           ]
  end

  test "get recording jobs" do
    xml_response = File.read!("test/fixtures/get_recording_jobs.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = Onvif.Recording2.get_recording_jobs(device)

    assert hd(response).job_token == "SD_DISK_20241120_211729_9C896594"
  end
end
