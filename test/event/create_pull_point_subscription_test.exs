defmodule Onvif.Event.CreatePullPointSubscriptionTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  alias Onvif.Event.Schemas.PullPointSubscription

  describe "CreatePullPointSubscription/1" do
    test "create pull point subscription" do
      xml_response = File.read!("test/event/fixtures/create_pull_point_subscription_success.xml")

      device = Onvif.Factory.device()

      Mimic.expect(Tesla, :request, fn _client, _opts ->
        {:ok, %{status: 200, body: xml_response}}
      end)

      {:ok, response} = Onvif.Event.CreatePullPointSubscription.request(device)

      assert response == %PullPointSubscription{
               subscription_reference: %PullPointSubscription.SubscriptionReference{
                 address: "http://192.168.8.120/onvif/Events/PullSubManager_20250415T164937Z_0"
               },
               current_time: ~U[2025-04-15 16:49:37Z],
               termination_time: ~U[2025-04-15 16:50:37Z]
             }
    end
  end
end
