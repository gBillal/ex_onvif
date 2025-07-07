defmodule ExOnvif.DevicesTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias ExOnvif.Devices.{
    DeviceInformation,
    HostnameInformation,
    NetworkProtocol,
    NTP,
    SystemDateAndTime
  }

  test "get device information" do
    xml_response = File.read!("test/fixtures/get_device_information.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert {:ok, response} = ExOnvif.Devices.get_device_information(device)

    assert response == %DeviceInformation{
             manufacturer: "Milesight Technology Co.,Ltd.",
             model: "MS-C8165-PE",
             firmware_version: "61.8.0.3-r8",
             serial_number: "EM82V102329001403",
             hardware_id: "V1.0"
           }

    assert {:ok, _json} = Jason.encode(response)
  end

  test "get hostname" do
    xml_response = File.read!("test/fixtures/get_hostname.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert {:ok, response} = ExOnvif.Devices.get_hostname(device)

    assert response == %HostnameInformation{name: nil, from_dhcp: false}
    assert {:ok, _json} = Jason.encode(response)
  end

  test "get network protocols" do
    xml_response = File.read!("test/fixtures/get_network_protocols.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert {:ok, network_protocols} = ExOnvif.Devices.get_network_protocols(device)

    assert network_protocols == [
             %NetworkProtocol{name: :http, enabled: true, port: 80},
             %NetworkProtocol{name: :https, enabled: false, port: 443},
             %NetworkProtocol{name: :rtsp, enabled: true, port: 554}
           ]

    assert {:ok, _json} = Jason.encode(network_protocols)
  end

  test "get ntp" do
    xml_response = File.read!("test/fixtures/get_ntp.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert {:ok, ntp} = ExOnvif.Devices.get_ntp(device)

    assert ntp == %NTP{
             from_dhcp: false,
             ntp_from_dhcp: nil,
             ntp_manual: %NTP.NTPManual{
               dns_name: "time.windows.com",
               ipv4_address: nil,
               ipv6_address: nil,
               type: :dns
             }
           }

    assert {:ok, _json} = Jason.encode(ntp)
  end

  test "get scopes" do
    xml_response = File.read!("test/fixtures/get_scopes.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert {:ok, scopes} = ExOnvif.Devices.get_scopes(device)

    assert scopes == [
             %ExOnvif.Devices.Scope{
               scope_def: :fixed,
               scope_item: "onvif://www.onvif.org/type/Network_Video_Transmitter"
             },
             %ExOnvif.Devices.Scope{
               scope_def: :fixed,
               scope_item: "onvif://www.onvif.org/Profile/Streaming"
             },
             %ExOnvif.Devices.Scope{
               scope_def: :fixed,
               scope_item: "onvif://www.onvif.org/hardware/Camera"
             },
             %ExOnvif.Devices.Scope{
               scope_def: :configurable,
               scope_item: "onvif://www.onvif.org/name/Camera"
             },
             %ExOnvif.Devices.Scope{
               scope_def: :configurable,
               scope_item: "onvif://www.onvif.org/location/"
             },
             %ExOnvif.Devices.Scope{
               scope_def: :configurable,
               scope_item: "onvif://www.onvif.org/model/"
             },
             %ExOnvif.Devices.Scope{
               scope_def: :configurable,
               scope_item: "onvif://www.onvif.org/macaddress/"
             },
             %ExOnvif.Devices.Scope{
               scope_def: :configurable,
               scope_item: "onvif://www.onvif.org/Profile/G"
             },
             %ExOnvif.Devices.Scope{
               scope_def: :configurable,
               scope_item: "onvif://www.onvif.org/Profile/T"
             },
             %ExOnvif.Devices.Scope{
               scope_def: :configurable,
               scope_item: "onvif://www.onvif.org/Profile/Q/FactoryDefault"
             }
           ]

    assert {:ok, _json} = Jason.encode(scopes)
  end

  test "get system date and time" do
    xml_response = File.read!("test/fixtures/get_system_date_and_time.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    Mimic.expect(DateTime, :utc_now, fn ->
      ~U[2024-07-09 20:00:00.227234Z]
    end)

    {:ok, service_capabilities} = ExOnvif.Devices.get_system_date_and_time(device)

    assert service_capabilities == %SystemDateAndTime{
             current_diff: -654,
             date_time_type: :manual,
             datetime: ~U[2024-07-09 19:49:06Z],
             daylight_savings: true,
             local_date_time: %SystemDateAndTime.LocalDateTime{
               date: %SystemDateAndTime.LocalDateTime.Date{
                 day: 9,
                 month: 7,
                 year: 2024
               },
               time: %SystemDateAndTime.LocalDateTime.Time{
                 hour: 16,
                 minute: 49,
                 second: 6
               }
             },
             time_zone: %SystemDateAndTime.TimeZone{
               tz: "BRT3"
             },
             utc_date_time: %SystemDateAndTime.UTCDateTime{
               date: %SystemDateAndTime.UTCDateTime.Date{
                 day: 9,
                 month: 7,
                 year: 2024
               },
               time: %SystemDateAndTime.UTCDateTime.Time{
                 hour: 19,
                 minute: 49,
                 second: 6
               }
             }
           }
  end
end
