defmodule Onvif.EventTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.Event.{Messages, PullPointSubscription, ServiceCapabilities}
  alias Onvif.Schemas.SimpleItem

  test "create pull point subscription" do
    xml_response = File.read!("test/fixtures/create_pull_point_subscription.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = Onvif.Event.create_pull_point_subscription(device)

    assert response == %PullPointSubscription{
             subscription_reference: %PullPointSubscription.SubscriptionReference{
               address: "http://192.168.8.120/onvif/Events/PullSubManager_20250415T164937Z_0"
             },
             current_time: ~U[2025-04-15 16:49:37Z],
             termination_time: ~U[2025-04-15 16:50:37Z]
           }
  end

  test "get service capabilities" do
    xml_response = File.read!("test/fixtures/get_event_service_capabilities.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    assert {:ok,
            %ServiceCapabilities{
              ws_subscription_policy_support: true,
              ws_pausable_subscription_manager_interface_support: false,
              max_notification_producers: 32,
              max_pull_points: 32,
              persistent_notification_storage: false,
              event_broker_protocols: [],
              max_event_brokers: 0,
              metadata_over_mqtt: false
            }} = Onvif.Event.get_service_capabilities(device)
  end

  test "pull messages" do
    xml_response = File.read!("test/fixtures/pull_messages.xml")

    device = Onvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = Onvif.PullPoint.pull_messages(device, "http://pull-point.com", timeout: 3)

    assert response == %Messages{
             current_time: ~U[2025-04-18 20:34:05Z],
             termination_time: ~U[2025-04-18 20:44:10Z],
             notification_messages: [
               %Messages.NotificationMessage{
                 topic: "tns1:VideoSource/MotionAlarm",
                 message: %Messages.NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "State", value: "false"}],
                   source: [%SimpleItem{name: "Source", value: "VideoSource_1"}]
                 }
               },
               %Messages.NotificationMessage{
                 topic: "tns1:RuleEngine/CellMotionDetector/Motion",
                 message: %Messages.NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "IsMotion", value: "false"}],
                   source: [
                     %SimpleItem{
                       name: "VideoSourceConfigurationToken",
                       value: "VideoSourceToken"
                     },
                     %SimpleItem{
                       name: "VideoAnalyticsConfigurationToken",
                       value: "VideoAnalyticsToken"
                     },
                     %SimpleItem{name: "Rule", value: "MyMotionDetectorRule"}
                   ]
                 }
               },
               %Messages.NotificationMessage{
                 topic: "tns1:RuleEngine/TamperDetector/Tamper",
                 message: %Messages.NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "IsTamper", value: "false"}],
                   source: [
                     %SimpleItem{
                       name: "VideoSourceConfigurationToken",
                       value: "VideoSourceToken"
                     },
                     %SimpleItem{
                       name: "VideoAnalyticsConfigurationToken",
                       value: "VideoAnalyticsToken"
                     },
                     %SimpleItem{name: "Rule", value: "MyTamperDetectorRule"}
                   ]
                 }
               },
               %Messages.NotificationMessage{
                 topic: "tns1:VideoSource/ImageTooDark/ImagingService",
                 message: %Messages.NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "State", value: "false"}],
                   source: [%SimpleItem{name: "Source", value: "VideoSourceToken"}]
                 }
               },
               %Messages.NotificationMessage{
                 topic: "tns1:RuleEngine/FieldDetector/ObjectsInside",
                 message: %Messages.NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "IsInside", value: "false"}],
                   key: [%SimpleItem{name: "ObjectId", value: "0"}],
                   source: [
                     %SimpleItem{
                       name: "VideoSourceConfigurationToken",
                       value: "VideoSourceToken"
                     },
                     %SimpleItem{
                       name: "VideoAnalyticsConfigurationToken",
                       value: "VideoAnalyticsToken"
                     },
                     %SimpleItem{name: "Rule", value: "MyFieldDetector1"}
                   ]
                 }
               },
               %Messages.NotificationMessage{
                 topic: "tns1:Monitoring/OperatingTime/LastReset",
                 message: %Messages.NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "Status", value: "2025-04-17T15:31:49Z"}],
                   source: []
                 }
               },
               %Messages.NotificationMessage{
                 topic: "tns1:Monitoring/OperatingTime/LastReboot",
                 message: %Messages.NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "Status", value: "2025-04-17T15:31:49Z"}],
                   source: []
                 }
               },
               %Messages.NotificationMessage{
                 topic: "tns1:Monitoring/OperatingTime/LastClockSynchronization",
                 message: %Messages.NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "Status", value: "2025-04-17T15:31:49Z"}],
                   source: []
                 }
               }
             ]
           }
  end
end
