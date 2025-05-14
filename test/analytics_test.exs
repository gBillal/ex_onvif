defmodule Onvif.AnalyticsTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.Analytics.{Module, ServiceCapabilities}

  test "get analytics modules" do
    xml_response = File.read!("test/fixtures/get_analytics_modules.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert {:ok,
            [
              %Module{
                name: "MyCellMotionModule",
                type: "tt:CellMotionEngine",
                parameters: %Module.Parameters{
                  simple_item: [
                    %Onvif.Schemas.SimpleItem{name: "sensitivity", value: "60"}
                  ],
                  element_item: [
                    %Module.Parameters.ElementItem{
                      name: "layout",
                      content: nil
                    }
                  ]
                }
              },
              %Onvif.Analytics.Module{
                name: "MyLineDetectorModule",
                type: "tt:LineDetectorEngine",
                parameters: %Module.Parameters{
                  simple_item: [
                    %Onvif.Schemas.SimpleItem{name: "sensitivity", value: "76"}
                  ],
                  element_item: [
                    %Module.Parameters.ElementItem{
                      name: "layout",
                      content: %{
                        scale: %{x: 0.002, y: 0.002},
                        translate: %{x: -1.0, y: -1.0}
                      }
                    },
                    %Module.Parameters.ElementItem{
                      name: "field",
                      content: nil
                    }
                  ]
                }
              },
              %Module{
                name: "MyFieldDetectorModule",
                type: "tt:FieldDetectorEngine",
                parameters: %Module.Parameters{
                  simple_item: [
                    %Onvif.Schemas.SimpleItem{name: "sensitivity", value: "50"}
                  ],
                  element_item: [
                    %Module.Parameters.ElementItem{
                      name: "layout",
                      content: %{
                        scale: %{x: 0.002, y: 0.002},
                        translate: %{x: -1.0, y: -1.0}
                      }
                    },
                    %Module.Parameters.ElementItem{
                      name: "field",
                      content: nil
                    }
                  ]
                }
              },
              %Module{
                name: "MyTamperDetecModule",
                type: "hikxsd:TamperEngine",
                parameters: %Module.Parameters{
                  simple_item: [%Onvif.Schemas.SimpleItem{name: "sensitivity", value: "0"}],
                  element_item: [
                    %Module.Parameters.ElementItem{
                      name: "transformation",
                      content: %{
                        scale: %{x: 0.002841, y: 0.003472},
                        translate: %{x: -1.0, y: -1.0}
                      }
                    },
                    %Module.Parameters.ElementItem{
                      name: "field",
                      content: nil
                    }
                  ]
                }
              }
            ]} = Onvif.Analytics.get_analytics_modules(device, "VideoAnalyticsToken")
  end

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
