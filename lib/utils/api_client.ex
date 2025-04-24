defmodule Onvif.Utils.ApiClient do
  @moduledoc false

  @devicemgmt_namespaces [
    "xmlns:tds": "http://www.onvif.org/ver10/device/wsdl",
    "xmlns:tt": "http://www.onvif.org/ver10/schema"
  ]

  @media_v10 [
    "xmlns:trt": "http://www.onvif.org/ver10/media/wsdl",
    "xmlns:tt": "http://www.onvif.org/ver10/schema"
  ]

  @media_v20 [
    "xmlns:tr2": "http://www.onvif.org/ver20/media/wsdl",
    "xmlns:tt": "http://www.onvif.org/ver10/schema"
  ]

  @recording_namespaces [
    "xmlns:trc": "http://www.onvif.org/ver10/recording/wsdl",
    "xmlns:tt": "http://www.onvif.org/ver10/schema"
  ]

  @search_namespaces [
    "xmlns:tse": "http://www.onvif.org/ver10/search/wsdl",
    "xmlns:tt": "http://www.onvif.org/ver10/schema"
  ]

  @replay_namespaces [
    "xmlns:trp": "http://www.onvif.org/ver10/replay/wsdl",
    "xmlns:tt": "http://www.onvif.org/ver10/schema"
  ]

  @ptz_namespaces [
    "xmlns:tt": "http://www.onvif.org/ver10/schema",
    "xmlns:tptz": "http://www.onvif.org/ver20/ptz/wsdl"
  ]

  def devicemgmt_request(device, action, content, parser_fn) do
    action = "http://www.onvif.org/ver10/device/wsdl/" <> action
    do_request(device, :device_service_path, @devicemgmt_namespaces, action, content, parser_fn)
  end

  def media_request(device, action, content, parser_fn) do
    action = "http://www.onvif.org/ver10/media/wsdl/" <> action

    do_request(
      device,
      :media_ver10_service_path,
      @media_v10,
      action,
      content,
      parser_fn
    )
  end

  def media2_request(device, action, content, parser_fn) do
    action = "http://www.onvif.org/ver20/media/wsdl/" <> action

    do_request(
      device,
      :media_ver20_service_path,
      @media_v20,
      action,
      content,
      parser_fn
    )
  end

  def recording_request(device, action, content, parser_fn) do
    action = "http://www.onvif.org/ver10/recording/wsdl/" <> action

    do_request(
      device,
      :recording_ver10_service_path,
      @recording_namespaces,
      action,
      content,
      parser_fn
    )
  end

  def search_request(device, action, content, parser_fn) do
    action = "http://www.onvif.org/ver10/search/wsdl/" <> action

    do_request(
      device,
      :search_ver10_service_path,
      @search_namespaces,
      action,
      content,
      parser_fn
    )
  end

  def replay_request(device, action, content, parser_fn) do
    action = "http://www.onvif.org/ver10/replay/wsdl/" <> action

    do_request(
      device,
      :replay_ver10_service_path,
      @replay_namespaces,
      action,
      content,
      parser_fn
    )
  end

  def ptz_request(device, action, content, parser_fn) do
    action = "http://www.onvif.org/ver20/ptz/wsdl/" <> action

    do_request(
      device,
      :ptz_ver20_service_path,
      @ptz_namespaces,
      action,
      content,
      parser_fn
    )
  end

  defp do_request(device, service_path, namespaces, action, content, parser_fn) do
    device
    |> Onvif.API.client(service_path: service_path)
    |> Tesla.request(
      method: :post,
      headers: [
        {"Content-Type", "application/soap+xml"},
        {"SOAPAction", action}
      ],
      body: %Onvif.Request{
        content: XmlBuilder.element(:"s:Body", List.wrap(content)),
        namespaces: namespaces
      }
    )
    |> parse_response(parser_fn)
  end

  defp parse_response({:ok, %{status: 200, body: body}}, parser_fn) do
    parser_fn.(body)
  end

  defp parse_response({:ok, %{status: status_code, body: body}}, _parser_fn)
       when status_code >= 400 do
    {:error, %{status: status_code, response: body}}
  end

  defp parse_response({:error, response}, _parser_fn) do
    {:error, %{status: nil, response: response}}
  end
end
