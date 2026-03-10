defmodule ExOnvif.EventTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias ExOnvif.Event.{
    EventProperties,
    ItemDescription,
    Messages,
    NotificationMessage,
    PullPointSubscription,
    ServiceCapabilities
  }

  alias ExOnvif.Schemas.SimpleItem

  test "get event properties" do
    xml_response = File.read!("test/fixtures/get_event_properties.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = ExOnvif.Event.get_event_properties(device)

    assert %EventProperties{
             topic_namespace_location: ["http://www.onvif.org/onvif/ver10/topics/topicns.xml"],
             fixed_topic_set: true,
             topic_expression_dialect: [
               "http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet",
               "http://docs.oasis-open.org/wsn/t-1/TopicExpression/Concrete"
             ],
             message_content_filter_dialect: [
               "http://www.onvif.org/ver10/tev/messageContentFilter/ItemFilter"
             ],
             message_content_schema_location: [
               "http://www.onvif.org/onvif/ver10/schema/onvif.xsd"
             ]
           } = response

    # 31 leaf topics across the topic tree (namespace prefixes are preserved in paths)
    assert length(response.topic_sets) == 31

    # Topic with SimpleItemDescription in source and data
    motion_alarm =
      Enum.find(response.topic_sets, &(&1.path == "tns1:VideoSource/MotionAlarm"))

    assert %EventProperties.TopicSet{
             path: "tns1:VideoSource/MotionAlarm",
             message_description: %EventProperties.TopicSet.MessageDescription{
               is_property: true,
               source: [
                 %ItemDescription{name: "Source", type: "tt:ReferenceToken", kind: :simple}
               ],
               key: [],
               data: [%ItemDescription{name: "State", type: "xs:boolean", kind: :simple}]
             }
           } = motion_alarm

    # Topic with ElementItemDescription in data
    profile =
      Enum.find(response.topic_sets, &(&1.path == "tns1:Configuration/Profile"))

    assert %EventProperties.TopicSet{
             message_description: %EventProperties.TopicSet.MessageDescription{
               is_property: false,
               source: [%ItemDescription{name: "Token", type: "tt:ReferenceToken", kind: :simple}],
               data: [
                 %ItemDescription{
                   name: "Configuration",
                   type: "tt:Profile",
                   kind: :element
                 }
               ]
             }
           } = profile

    # Topic with Key element
    objects_inside =
      Enum.find(
        response.topic_sets,
        &(&1.path == "tns1:RuleEngine/FieldDetector/ObjectsInside")
      )

    assert %EventProperties.TopicSet{
             message_description: %EventProperties.TopicSet.MessageDescription{
               is_property: true,
               source: [
                 %ItemDescription{name: "VideoSourceConfigurationToken", kind: :simple},
                 %ItemDescription{name: "VideoAnalyticsConfigurationToken", kind: :simple},
                 %ItemDescription{name: "Rule", kind: :simple}
               ],
               key: [%ItemDescription{name: "ObjectId", type: "xs:integer", kind: :simple}],
               data: [%ItemDescription{name: "IsInside", type: "xs:boolean", kind: :simple}]
             }
           } = objects_inside

    # Topic with no MessageDescription
    ethernet_broken =
      Enum.find(
        response.topic_sets,
        &(&1.path == "tns1:Device/tnshik:Network/tnshik:EthernetBroken")
      )

    assert %EventProperties.TopicSet{
             path: "tns1:Device/tnshik:Network/tnshik:EthernetBroken",
             message_description: nil
           } = ethernet_broken
  end

  test "create pull point subscription" do
    xml_response = File.read!("test/fixtures/create_pull_point_subscription.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = ExOnvif.Event.create_pull_point_subscription(device)

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

    device = ExOnvif.Factory.device()

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
            }} = ExOnvif.Event.get_service_capabilities(device)
  end

  test "pull messages" do
    xml_response = File.read!("test/fixtures/pull_messages.xml")

    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 200, body: xml_response}}
    end)

    {:ok, response} = ExOnvif.PullPoint.pull_messages(device, "http://pull-point.com", timeout: 3)

    assert response == %Messages{
             current_time: ~U[2025-04-18 20:34:05Z],
             termination_time: ~U[2025-04-18 20:44:10Z],
             notification_messages: [
               %NotificationMessage{
                 topic: "tns1:VideoSource/MotionAlarm",
                 message: %NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05.000000Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "state", value: "false"}],
                   source: [%SimpleItem{name: "source", value: "VideoSource_1"}]
                 }
               },
               %NotificationMessage{
                 topic: "tns1:RuleEngine/CellMotionDetector/Motion",
                 message: %NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05.000000Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "is_motion", value: "false"}],
                   source: [
                     %SimpleItem{
                       name: "video_source_configuration_token",
                       value: "VideoSourceToken"
                     },
                     %SimpleItem{
                       name: "video_analytics_configuration_token",
                       value: "VideoAnalyticsToken"
                     },
                     %SimpleItem{name: "rule", value: "MyMotionDetectorRule"}
                   ]
                 }
               },
               %NotificationMessage{
                 topic: "tns1:RuleEngine/TamperDetector/Tamper",
                 message: %NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05.000000Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "is_tamper", value: "false"}],
                   source: [
                     %SimpleItem{
                       name: "video_source_configuration_token",
                       value: "VideoSourceToken"
                     },
                     %SimpleItem{
                       name: "video_analytics_configuration_token",
                       value: "VideoAnalyticsToken"
                     },
                     %SimpleItem{name: "rule", value: "MyTamperDetectorRule"}
                   ]
                 }
               },
               %NotificationMessage{
                 topic: "tns1:VideoSource/ImageTooDark/ImagingService",
                 message: %NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05.000000Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "state", value: "false"}],
                   source: [%SimpleItem{name: "source", value: "VideoSourceToken"}]
                 }
               },
               %NotificationMessage{
                 topic: "tns1:RuleEngine/FieldDetector/ObjectsInside",
                 message: %NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05.000000Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "is_inside", value: "false"}],
                   key: [%SimpleItem{name: "object_id", value: "0"}],
                   source: [
                     %SimpleItem{
                       name: "video_source_configuration_token",
                       value: "VideoSourceToken"
                     },
                     %SimpleItem{
                       name: "video_analytics_configuration_token",
                       value: "VideoAnalyticsToken"
                     },
                     %SimpleItem{name: "rule", value: "MyFieldDetector1"}
                   ]
                 }
               },
               %NotificationMessage{
                 topic: "tns1:Monitoring/OperatingTime/LastReset",
                 message: %NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05.000000Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "status", value: "2025-04-17T15:31:49Z"}],
                   source: []
                 }
               },
               %NotificationMessage{
                 topic: "tns1:Monitoring/OperatingTime/LastReboot",
                 message: %NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05.000000Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "status", value: "2025-04-17T15:31:49Z"}],
                   source: []
                 }
               },
               %NotificationMessage{
                 topic: "tns1:Monitoring/OperatingTime/LastClockSynchronization",
                 message: %NotificationMessage.Message{
                   utc_time: ~U[2025-04-18 20:34:05.000000Z],
                   property_operation: :initialized,
                   data: [%SimpleItem{name: "status", value: "2025-04-17T15:31:49Z"}],
                   source: []
                 }
               }
             ]
           }
  end
end
