defmodule Onvif.SearchTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.Search.FindEvents
  alias Onvif.Search.Schemas.SearchScope

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
end
