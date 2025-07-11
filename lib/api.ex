defmodule ExOnvif.API do
  @moduledoc false

  @spec client(ExOnvif.Device.t(), Keyword.t()) :: Tesla.Client.t()
  def client(device, opts \\ [service_path: :device_service_path]) do
    adapter = {Tesla.Adapter.Finch, name: ExOnvif.Finch}
    service_path = get_service_path!(device, opts)

    url = device.address <> service_path

    middleware = [
      {Tesla.Middleware.BaseUrl, url},
      auth_function(device),
      {Tesla.Middleware.Logger, log_level: :info}
    ]

    Tesla.client(middleware, adapter)
  end

  @spec pull_point_client(ExOnvif.Device.t(), String.t()) :: Tesla.Client.t()
  def pull_point_client(device, url) do
    adapter = {Tesla.Adapter.Finch, name: ExOnvif.Finch}

    middleware = [
      {Tesla.Middleware.BaseUrl, url},
      auth_function(device),
      {Tesla.Middleware.Logger, log_level: :info}
    ]

    Tesla.client(middleware, adapter)
  end

  defp auth_function(%{auth_type: :no_auth}), do: ExOnvif.Middleware.NoAuth

  defp auth_function(%{auth_type: :basic_auth} = device),
    do: {ExOnvif.Middleware.PlainAuth, device: device}

  defp auth_function(%{auth_type: :xml_auth} = device),
    do: {ExOnvif.Middleware.XmlAuth, device: device}

  defp auth_function(%{auth_type: :digest_auth} = device),
    do: {ExOnvif.Middleware.DigestAuth, device: device}

  def get_service_path!(device, opts) do
    case Map.fetch!(device, opts[:service_path]) do
      nil -> raise "The service operation is not supported by the device"
      service_path -> service_path
    end
  end
end
