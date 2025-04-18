defmodule Onvif.Event.PullMessagesTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.Event.Schemas.{PullMessages, PullMessagesRequest}

  describe "PullMessages/1" do
    test "pull messages" do
      xml_response = File.read!("test/event/fixtures/pull_messages_success.xml")

      device = Onvif.Factory.device()

      Mimic.expect(Tesla, :request, fn _client, _opts ->
        {:ok, %{status: 200, body: xml_response}}
      end)

      {:ok, response} =
        Onvif.Event.PullMessages.request(device, "http://pull-point.com", %PullMessagesRequest{
          timeout: 5,
          message_limit: 10
        })

      assert response == %PullMessages{
               current_time: ~U[2025-04-18 20:34:05Z],
               termination_time: ~U[2025-04-18 20:44:10Z],
               notification_messages: [
                 %PullMessages.NotificationMessage{
                   topic: "tns1:VideoSource/MotionAlarm",
                   message: %PullMessages.NotificationMessage.Message{
                     utc_time: ~U[2025-04-18 20:34:05Z],
                     property_operation: :initialized,
                     data: %{"State" => "false"},
                     source: %{"Source" => "VideoSource_1"}
                   }
                 },
                 %PullMessages.NotificationMessage{
                   topic: "tns1:RuleEngine/CellMotionDetector/Motion",
                   message: %PullMessages.NotificationMessage.Message{
                     utc_time: ~U[2025-04-18 20:34:05Z],
                     property_operation: :initialized,
                     data: %{"IsMotion" => "false"},
                     source: %{
                       "Rule" => "MyMotionDetectorRule",
                       "VideoAnalyticsConfigurationToken" => "VideoAnalyticsToken",
                       "VideoSourceConfigurationToken" => "VideoSourceToken"
                     }
                   }
                 },
                 %PullMessages.NotificationMessage{
                   topic: "tns1:RuleEngine/TamperDetector/Tamper",
                   message: %PullMessages.NotificationMessage.Message{
                     utc_time: ~U[2025-04-18 20:34:05Z],
                     property_operation: :initialized,
                     data: %{"IsTamper" => "false"},
                     source: %{
                       "Rule" => "MyTamperDetectorRule",
                       "VideoAnalyticsConfigurationToken" => "VideoAnalyticsToken",
                       "VideoSourceConfigurationToken" => "VideoSourceToken"
                     }
                   }
                 },
                 %PullMessages.NotificationMessage{
                   topic: "tns1:VideoSource/ImageTooDark/ImagingService",
                   message: %PullMessages.NotificationMessage.Message{
                     utc_time: ~U[2025-04-18 20:34:05Z],
                     property_operation: :initialized,
                     data: %{"State" => "false"},
                     source: %{"Source" => "VideoSourceToken"}
                   }
                 },
                 %PullMessages.NotificationMessage{
                   topic: "tns1:RuleEngine/FieldDetector/ObjectsInside",
                   message: %PullMessages.NotificationMessage.Message{
                     utc_time: ~U[2025-04-18 20:34:05Z],
                     property_operation: :initialized,
                     data: %{"IsInside" => "false"},
                     source: %{
                       "Rule" => "MyFieldDetector1",
                       "VideoAnalyticsConfigurationToken" => "VideoAnalyticsToken",
                       "VideoSourceConfigurationToken" => "VideoSourceToken"
                     }
                   }
                 },
                 %PullMessages.NotificationMessage{
                   topic: "tns1:Monitoring/OperatingTime/LastReset",
                   message: %PullMessages.NotificationMessage.Message{
                     utc_time: ~U[2025-04-18 20:34:05Z],
                     property_operation: :initialized,
                     data: %{"Status" => "2025-04-17T15:31:49Z"},
                     source: %{}
                   }
                 },
                 %PullMessages.NotificationMessage{
                   topic: "tns1:Monitoring/OperatingTime/LastReboot",
                   message: %PullMessages.NotificationMessage.Message{
                     utc_time: ~U[2025-04-18 20:34:05Z],
                     property_operation: :initialized,
                     data: %{"Status" => "2025-04-17T15:31:49Z"},
                     source: %{}
                   }
                 },
                 %PullMessages.NotificationMessage{
                   topic: "tns1:Monitoring/OperatingTime/LastClockSynchronization",
                   message: %PullMessages.NotificationMessage.Message{
                     utc_time: ~U[2025-04-18 20:34:05Z],
                     property_operation: :initialized,
                     data: %{"Status" => "2025-04-17T15:31:49Z"},
                     source: %{}
                   }
                 }
               ]
             }
    end
  end
end
