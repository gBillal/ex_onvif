defmodule Onvif.PTZTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.PTZ.{Node, ServiceCapabilities, Status}
  alias Onvif.Schemas.FloatRange

  test "get node" do
    xml_response = File.read!("test/fixtures/get_ptz_node.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert {:ok,
            %Node{
              token: "PTZNodeToken002",
              fixed_home_position: nil,
              geo_move: nil,
              name: "PTZNodeName002",
              supported_ptz_spaces: %Node.SupportedPTZSpaces{
                absolute_pan_tilt_position_space: nil,
                absolute_zoom_position_space: nil,
                relative_pan_tilt_translation_space: nil,
                relative_zoom_translation_space: nil,
                continuous_pan_tilt_velocity_space: %Onvif.Schemas.Space2DDescription{
                  uri: "http://www.onvif.org/ver10/tptz/PanTiltSpaces/VelocityGenericSpace",
                  x_range: %FloatRange{min: -1.0, max: 1.0},
                  y_range: %FloatRange{min: -1.0, max: 1.0}
                },
                continuous_zoom_velocity_space: %Onvif.Schemas.Space1DDescription{
                  uri: "http://www.onvif.org/ver10/tptz/ZoomSpaces/VelocityGenericSpace",
                  x_range: %FloatRange{min: -1.0, max: 1.0}
                },
                pan_tilt_speed_space: nil,
                zoom_speed_space: nil
              },
              maximum_number_of_presets: 255,
              home_supported: false,
              auxiliary_commands: [],
              extension: %Node.Extension{
                supported_preset_tour: %Node.Extension.SupportedPresetTour{
                  maximum_number_of_preset_tours: 4,
                  ptz_preset_tour_operation: ["Start", "Stop"]
                }
              }
            }} = Onvif.PTZ.get_node(device, "PTZNodeToken001")
  end

  test "get nodes" do
    xml_response = File.read!("test/fixtures/get_ptz_nodes.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = Onvif.PTZ.get_nodes(device)

    assert response == [
             %Node{
               token: "PTZNodeToken",
               fixed_home_position: nil,
               geo_move: nil,
               name: "PTZNode",
               supported_ptz_spaces: %Node.SupportedPTZSpaces{
                 absolute_pan_tilt_position_space: %Onvif.Schemas.Space2DDescription{
                   uri: "http://www.onvif.org/ver10/tptz/PanTiltSpaces/PositionGenericSpace",
                   x_range: %FloatRange{
                     min: -1.0,
                     max: 1.0
                   },
                   y_range: %FloatRange{
                     min: -1.0,
                     max: 1.0
                   }
                 },
                 absolute_zoom_position_space: %Onvif.Schemas.Space1DDescription{
                   uri: "http://www.onvif.org/ver10/tptz/ZoomSpaces/PositionGenericSpace",
                   x_range: %FloatRange{
                     min: 0.0,
                     max: 1.0
                   }
                 },
                 relative_pan_tilt_translation_space: %Onvif.Schemas.Space2DDescription{
                   uri: "http://www.onvif.org/ver10/tptz/PanTiltSpaces/TranslationGenericSpace",
                   x_range: %FloatRange{
                     min: -1.0,
                     max: 1.0
                   },
                   y_range: %FloatRange{
                     min: -1.0,
                     max: 1.0
                   }
                 },
                 relative_zoom_translation_space: %Onvif.Schemas.Space1DDescription{
                   uri: "http://www.onvif.org/ver10/tptz/ZoomSpaces/TranslationGenericSpace",
                   x_range: %FloatRange{
                     min: -1.0,
                     max: 1.0
                   }
                 },
                 continuous_pan_tilt_velocity_space: %Onvif.Schemas.Space2DDescription{
                   uri: "http://www.onvif.org/ver10/tptz/PanTiltSpaces/VelocityGenericSpace",
                   x_range: %FloatRange{
                     min: -1.0,
                     max: 1.0
                   },
                   y_range: %FloatRange{
                     min: -1.0,
                     max: 1.0
                   }
                 },
                 continuous_zoom_velocity_space: %Onvif.Schemas.Space1DDescription{
                   uri: "http://www.onvif.org/ver10/tptz/ZoomSpaces/VelocityGenericSpace",
                   x_range: %FloatRange{
                     min: -1.0,
                     max: 1.0
                   }
                 },
                 pan_tilt_speed_space: %Onvif.Schemas.Space1DDescription{
                   uri: "http://www.onvif.org/ver10/tptz/PanTiltSpaces/GenericSpeedSpace",
                   x_range: %FloatRange{
                     min: 0.0,
                     max: 1.0
                   }
                 },
                 zoom_speed_space: %Onvif.Schemas.Space1DDescription{
                   uri: "http://www.onvif.org/ver10/tptz/ZoomSpaces/ZoomGenericSpeedSpace",
                   x_range: %FloatRange{
                     min: 0.0,
                     max: 1.0
                   }
                 }
               },
               maximum_number_of_presets: 300,
               home_supported: true,
               auxiliary_commands: [
                 "focusout",
                 "focusin",
                 "autofocus",
                 "resetfocus",
                 "irisout",
                 "irisin",
                 "auto",
                 "lightoff",
                 "lighton",
                 "brushoff",
                 "brushon"
               ],
               extension: %Node.Extension{
                 supported_preset_tour: %Node.Extension.SupportedPresetTour{
                   maximum_number_of_preset_tours: 8,
                   ptz_preset_tour_operation: ["Start"]
                 }
               }
             }
           ]
  end

  test "get service capabilities" do
    xml_response = File.read!("test/fixtures/get_ptz_service_capabilities.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = Onvif.PTZ.get_service_capabilities(device)

    assert response == %ServiceCapabilities{
             eflip: false,
             reverse: false,
             get_compatible_configurations: true,
             move_status: true,
             status_position: true,
             move_and_track: []
           }
  end

  test "get ptz status" do
    xml_response = File.read!("test/fixtures/get_ptz_status.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = Onvif.PTZ.get_status(device, "Profile_1")

    assert response == %Status{
             position: %Onvif.PTZ.Vector{
               pan_tilt: %Onvif.PTZ.Vector.PanTilt{
                 x: 0.164178,
                 y: -0.618316,
                 space: "http://www.onvif.org/ver10/tptz/PanTiltSpaces/PositionGenericSpace"
               },
               zoom: 0.0
             },
             move_status: %Onvif.PTZ.Status.MoveStatus{
               pan_tilt: :idle,
               zoom: :idle
             },
             utc_time: ~U[2025-04-05 20:37:31Z]
           }
  end
end
