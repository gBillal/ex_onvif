defmodule Onvif.Event.CreatePullPointSubscription do
  @moduledoc """
  This method returns a PullPointSubscription that can be polled using PullMessages.
  This message contains the same elements as the SubscriptionRequest of the WS-BaseNotification without the ConsumerReference.

  If no Filter is specified the pullpoint notifies all occurring events to the client.
  """

  import SweetXml
  import XmlBuilder

  require Logger

  alias Onvif.Event.Schemas.PullPointSubscription

  def soap_action(),
    do: "http://www.onvif.org/ver10/events/wsdl/EventPortType/CreatePullPointSubscriptionRequest"

  @spec request(Device.t()) :: {:ok, map()} | {:error, map()}
  @spec request(Device.t(), String.t() | nil) :: {:ok, map()} | {:error, map()}
  def request(device, args \\ nil), do: Onvif.Event.request(device, args, __MODULE__)

  def request_body(nil), do: element(:"s:Body", [element(:"tev:CreatePullPointSubscription", [])])

  # only support ConcreteSet filters.
  def request_body(filter) do
    element(:"s:Body", [
      element(:"tev:CreatePullPointSubscription", [
        element(:"wsnt:Filter", [
          element(
            "TopicExpression",
            [Dialect: "http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet"],
            [filter]
          )
        ])
      ])
    ])
  end

  def response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tev:CreatePullPointSubscriptionResponse"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      |> add_namespace("tev", "http://www.onvif.org/ver10/event/wsdl")
      |> add_namespace("wsnt", "http://docs.oasis-open.org/wsn/b-2")
    )
    |> PullPointSubscription.parse()
    |> PullPointSubscription.to_struct()
  end
end
