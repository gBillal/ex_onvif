defmodule Onvif.SearchTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.Search.{
    FindEvents,
    FindRecordingResult,
    FindRecordings,
    GetRecordingSearchResults,
    RecordingInformation,
    SearchScope
  }

  test "find events" do
    xml_response = File.read!("test/fixtures/find_events.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} =
      Onvif.Search.find_events(device, %FindEvents{
        start_point: ~U(2024-12-06 19:00:00Z),
        end_point: ~U(2024-12-06 19:02:00Z),
        keep_alive_time: 60,
        search_scope: %SearchScope{included_recordings: ["Record_004"]}
      })

    assert response == "SearchToken[1]"
  end

  test "find recordings" do
    xml_response = File.read!("test/fixtures/find_recordings.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} =
      Onvif.Search.find_recordings(device, %FindRecordings{
        max_matches: 10,
        keep_alive_time: 5
      })

    assert response == "RecordingSearchToken_1"
  end

  test "get recordings search results" do
    xml_response = File.read!("test/fixtures/get_recording_search_results.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} =
      Onvif.Search.get_recording_search_results(device, %GetRecordingSearchResults{
        search_token: "RecordingSearchToken_1",
        max_results: 10,
        min_results: 2,
        wait_time: 5
      })

    assert response == %FindRecordingResult{
             search_state: :completed,
             recording_information: [
               %RecordingInformation{
                 recording_token: "OnvifRecordingToken_1",
                 source: %RecordingInformation.RecordingSourceInformation{
                   source_id: "SourceId_1",
                   name: "IpCamera_1",
                   location: "Location",
                   description: "Description of source",
                   address: "http://www.onvif.org/ver10/schema/Profile"
                 },
                 earliest_recording: ~U[1970-01-01 00:03:15Z],
                 latest_recording: ~U[2025-03-15 16:28:00Z],
                 content: "RecordContent",
                 tracks: [
                   %RecordingInformation.TrackInformation{
                     track_token: "videotracktoken_1",
                     track_type: :video,
                     description: "VideoTrack",
                     data_from: ~U[1970-01-01 00:03:15Z],
                     data_to: ~U[2025-03-15 16:28:00Z]
                   },
                   %RecordingInformation.TrackInformation{
                     track_token: "audiotracktoken_1",
                     track_type: :audio,
                     description: "AudioTrack",
                     data_from: ~U[1970-01-01 00:03:15Z],
                     data_to: ~U[2025-03-15 16:28:00Z]
                   },
                   %RecordingInformation.TrackInformation{
                     track_token: "metadatatracktoken_1",
                     track_type: :metadata,
                     description: "MetadataTrack",
                     data_from: ~U[1970-01-01 00:03:15Z],
                     data_to: ~U[2025-03-15 16:28:00Z]
                   }
                 ],
                 recording_status: :stopped
               }
             ]
           }
  end
end
