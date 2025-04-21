defmodule Onvif.RecordingTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.Recording.{JobConfiguration, RecordingConfiguration, RecordingJob}

  test "create recording" do
    xml_response = File.read!("test/fixtures/create_recording.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response_uri} =
      Onvif.Recording.create_recording(device, %RecordingConfiguration{
        content: "test",
        maximum_retention_time: "PT1H",
        source: %RecordingConfiguration.Source{
          name: "test"
        }
      })

    assert response_uri == "SD_DISK_20200422_123501_A2388AB3"
  end

  test "create recording job" do
    xml_response = File.read!("test/fixtures/create_recording_job.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert {:ok, response} =
             Onvif.Recording.create_recording_job(device, %JobConfiguration{
               recording_token: "SD_DISK_20241120_211729_9C896594",
               priority: 9,
               mode: :active
             })

    assert %RecordingJob{
             job_token: "SD_DISK_20241120_211729_9C896594",
             job_configuration: %JobConfiguration{
               recording_token: "SD_DISK_20241120_211729_9C896594",
               priority: 9,
               mode: :active
             }
           } = response
  end

  test "get recordings" do
    xml_response = File.read!("test/fixtures/get_recordings.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = Onvif.Recording.get_recordings(device)

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

    {:ok, response} = Onvif.Recording.get_recording_jobs(device)

    assert hd(response).job_token == "SD_DISK_20241120_211729_9C896594"
  end
end
