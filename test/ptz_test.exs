defmodule ExOnvif.PTZTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias ExOnvif.PTZ.{Node, ServiceCapabilities, Status, PTZConfigurations}
  alias ExOnvif.Schemas.FloatRange

  test "get node" do
    xml_response = File.read!("test/fixtures/get_ptz_node.xml")

    device = ExOnvif.Factory.device()

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
                continuous_pan_tilt_velocity_space: %ExOnvif.Schemas.Space2DDescription{
                  uri: "http://www.onvif.org/ver10/tptz/PanTiltSpaces/VelocityGenericSpace",
                  x_range: %FloatRange{min: -1.0, max: 1.0},
                  y_range: %FloatRange{min: -1.0, max: 1.0}
                },
                continuous_zoom_velocity_space: %ExOnvif.Schemas.Space1DDescription{
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
            }} = ExOnvif.PTZ.get_node(device, "PTZNodeToken001")
  end

  test "get nodes" do
    xml_response = File.read!("test/fixtures/get_ptz_nodes.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = ExOnvif.PTZ.get_nodes(device)

    assert response == [
             %Node{
               token: "PTZNodeToken",
               fixed_home_position: nil,
               geo_move: nil,
               name: "PTZNode",
               supported_ptz_spaces: %Node.SupportedPTZSpaces{
                 absolute_pan_tilt_position_space: %ExOnvif.Schemas.Space2DDescription{
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
                 absolute_zoom_position_space: %ExOnvif.Schemas.Space1DDescription{
                   uri: "http://www.onvif.org/ver10/tptz/ZoomSpaces/PositionGenericSpace",
                   x_range: %FloatRange{
                     min: 0.0,
                     max: 1.0
                   }
                 },
                 relative_pan_tilt_translation_space: %ExOnvif.Schemas.Space2DDescription{
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
                 relative_zoom_translation_space: %ExOnvif.Schemas.Space1DDescription{
                   uri: "http://www.onvif.org/ver10/tptz/ZoomSpaces/TranslationGenericSpace",
                   x_range: %FloatRange{
                     min: -1.0,
                     max: 1.0
                   }
                 },
                 continuous_pan_tilt_velocity_space: %ExOnvif.Schemas.Space2DDescription{
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
                 continuous_zoom_velocity_space: %ExOnvif.Schemas.Space1DDescription{
                   uri: "http://www.onvif.org/ver10/tptz/ZoomSpaces/VelocityGenericSpace",
                   x_range: %FloatRange{
                     min: -1.0,
                     max: 1.0
                   }
                 },
                 pan_tilt_speed_space: %ExOnvif.Schemas.Space1DDescription{
                   uri: "http://www.onvif.org/ver10/tptz/PanTiltSpaces/GenericSpeedSpace",
                   x_range: %FloatRange{
                     min: 0.0,
                     max: 1.0
                   }
                 },
                 zoom_speed_space: %ExOnvif.Schemas.Space1DDescription{
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

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = ExOnvif.PTZ.get_service_capabilities(device)

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

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = ExOnvif.PTZ.get_status(device, "Profile_1")

    assert response == %Status{
             position: %ExOnvif.PTZ.Vector{
               pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{
                 x: 0.164178,
                 y: -0.618316,
                 space: "http://www.onvif.org/ver10/tptz/PanTiltSpaces/PositionGenericSpace"
               },
               zoom: 0.0
             },
             move_status: %ExOnvif.PTZ.Status.MoveStatus{
               pan_tilt: :idle,
               zoom: :idle
             },
             utc_time: ~U[2025-04-05 20:37:31Z]
           }
  end

  test "get ptz configurations" do
    xml_response = File.read!("test/fixtures/get_configurations.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = ExOnvif.PTZ.get_configurations(device, "Profile_1")

    assert response == %ExOnvif.PTZ.PTZConfigurations{
             token: "PTZToken",
             name: nil,
             use_count: 1,
             move_ramp: nil,
             present_ramp: nil,
             preset_tour_ramp: nil,
             node_token: "PTZNodeToken",
             default_absolute_pan_tilt_position_space:
               "http://www.onvif.org/ver10/tptz/PanTiltSpaces/PositionGenericSpace",
             default_absolute_zoom_position_space:
               "http://www.onvif.org/ver10/tptz/ZoomSpaces/PositionGenericSpace",
             default_relative_pan_tilt_translation_space:
               "http://www.onvif.org/ver10/tptz/PanTiltSpaces/TranslationGenericSpace",
             default_relative_zoom_translation_space:
               "http://www.onvif.org/ver10/tptz/ZoomSpaces/TranslationGenericSpace",
             default_continuous_pan_tilt_velocity_space:
               "http://www.onvif.org/ver10/tptz/PanTiltSpaces/VelocityGenericSpace",
             default_continuous_zoom_velocity_space:
               "http://www.onvif.org/ver10/tptz/ZoomSpaces/VelocityGenericSpace",
             default_ptz_speed: %ExOnvif.PTZ.Vector{
               pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{
                 x: 0.1,
                 y: 0.1,
                 space: "http://www.onvif.org/ver10/tptz/PanTiltSpaces/GenericSpeedSpace"
               },
               zoom: 1.0
             },
             default_ptz_timeout: nil,
             pan_tilt_limits: %ExOnvif.Schemas.Space2DDescription{
               uri: nil,
               x_range: nil,
               y_range: nil
             },
             zoom_limits: %ExOnvif.Schemas.Space1DDescription{uri: nil, x_range: nil},
             extension: nil
           }
  end

  test "get presets" do
    xml_response = File.read!("test/fixtures/get_presets.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)


    response = ExOnvif.PTZ.get_presets(device, "Profile_1")

    expected =  [
  %ExOnvif.PTZ.Presets{
    token: "33",
    name: "Auto Flip",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "34",
    name: "Goto Zero",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "35",
    name: "Self Check",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "36",
    name: "Patrol",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "37",
    name: "Path1",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "38",
    name: "Path2",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "39",
    name: "Path3",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "40",
    name: "Path4",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "41",
    name: "Path5",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "42",
    name: "Path6",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "43",
    name: "Path7",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "44",
    name: "Path8",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "45",
    name: "Pattern1",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "46",
    name: "Pattern2",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "47",
    name: "Pattern3",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "48",
    name: "Pattern4",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "49",
    name: "Stop Scan",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "50",
    name: "Auto Scan",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "51",
    name: "Tilt Scan",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  },
  %ExOnvif.PTZ.Presets{
    token: "52",
    name: "Panorama Scan",
    ptz_position: %ExOnvif.PTZ.Vector{
      pan_tilt: %ExOnvif.PTZ.Vector.PanTilt{x: 0.0, y: 0.0, space: nil},
      zoom: nil,
      zoom_space: nil
    }
  }
]
   
  end
end
