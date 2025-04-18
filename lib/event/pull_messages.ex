defmodule Onvif.Event.PullMessages do
  @moduledoc """
  This method pulls one or more messages from a PullPoint. The device shall provide the following
  PullMessages command for all SubscriptionManager endpoints returned by the `Onvif.Event.CreatePullPointSubscription`.
  This method shall not wait until the requested number of messages is available but return as soon as at least one message is available.

  The command shall at least support a Timeout of one minute. In case a device supports retrieval of less messages than requested
  it shall return these without generating a fault.
  """

  import XmlBuilder
  import SweetXml

  alias Onvif.Event.Schemas.{PullMessages, PullMessagesRequest}

  def soap_action(),
    do: "http://www.onvif.org/ver10/events/wsdl/PullPointSubscription/PullMessagesRequest"

  @spec request(Device.t(), String.t(), PullMessagesRequest.t()) :: {:ok, map()} | {:error, map()}
  def request(device, url, args) do
    Onvif.Event.PullPoint.request(device, url, args, __MODULE__)
  end

  def request_body(%PullMessagesRequest{} = req),
    do: element(:"s:Body", [PullMessagesRequest.to_xml(req)])

  def request_header(%PullMessagesRequest{subscription_id: nil}), do: []
  def request_header(%PullMessagesRequest{subscription_id: id}), do: [subscription_id: id]

  def response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tev:PullMessagesResponse"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      |> add_namespace("tev", "http://www.onvif.org/ver10/event/wsdl")
      |> add_namespace("wsnt", "http://docs.oasis-open.org/wsn/b-2")
    )
    |> PullMessages.parse()
    |> PullMessages.to_struct()
  end
end
