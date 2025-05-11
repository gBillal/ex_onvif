defmodule Onvif.AnalyticsTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.Analytics.{ServiceCapabilities}

  test "get service capabilities" do
    xml_response = File.read!("test/fixtures/get_analytics_service_capabilities.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert {:ok,
            %ServiceCapabilities{
              rule_support: true,
              analytics_module_support: true,
              cell_based_scene_description_supported: true,
              rule_options_supported: false,
              analytics_module_options_supported: false,
              supported_metadata: false,
              image_sending_type: []
            }} = Onvif.Analytics.get_service_capabilities(device)
  end
end
