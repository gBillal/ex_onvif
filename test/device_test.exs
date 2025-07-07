defmodule ExOnvif.DeviceTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true

  describe "to_struct/1" do
    test "should parse given map to a valid device struct" do
      device_map = ExOnvif.Factory.device() |> Jason.encode!() |> Jason.decode!()
      {:ok, device} = ExOnvif.Device.to_struct(device_map)
      assert device == ExOnvif.Factory.device()
    end
  end
end
