defmodule Onvif.EventTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.Event.{PullPointSubscription, ServiceCapabilities}

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
end
