defmodule Onvif.Event.PullPoint do
  @moduledoc false

  require Logger
  alias Onvif.Device

  @namespaces [
    "xmlns:tds": "http://www.onvif.org/ver10/device/wsdl",
    "xmlns:tt": "http://www.onvif.org/ver10/schema",
    "xmlns:tev": "http://www.onvif.org/ver10/events/wsdl",
    "xmlns:wsnt": "http://docs.oasis-open.org/wsn/b-2",
    "xmlns:wsa": "http://www.w3.org/2005/08/addressing"
  ]

  @spec request(Device.t(), String.t(), module()) :: {:ok, any} | {:error, map()}
  @spec request(Device.t(), String.t(), any(), atom()) :: {:ok, any} | {:error, map()}
  def request(%Device{} = device, url, args \\ [], operation) do
    content = generate_content(operation, args)
    headers = generate_header(operation, args)
    do_request(device, url, operation, headers, content)
  end

  defp do_request(device, url, operation, headers, content) do
    request = %Onvif.Request{
      content: content,
      namespaces: @namespaces
    }

    request =
      Enum.reduce(headers, request, fn {key, value}, request ->
        Onvif.Request.put_header(request, key, value)
      end)

    device
    |> Onvif.API.pull_point_client(url)
    |> Tesla.request(
      method: :post,
      headers: [{"Content-Type", "application/soap+xml"}],
      body: request
    )
    |> parse_response(operation)
  end

  defp generate_content(operation, []), do: operation.request_body()
  defp generate_content(operation, args), do: operation.request_body(args)

  defp generate_header(operation, args), do: operation.request_header(args)

  defp parse_response({:ok, %{status: 200, body: body}}, operation) do
    operation.response(body)
  end

  defp parse_response({:ok, %{status: status_code, body: body}}, operation)
       when status_code >= 400,
       do:
         {:error,
          %{
            status: status_code,
            reason: "Received #{status_code} from #{operation}",
            response: body
          }}

  defp parse_response({:error, response}, operation) do
    {:error, %{status: nil, reason: "Error performing #{operation}", response: response}}
  end
end
