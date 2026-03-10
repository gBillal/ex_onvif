defmodule ExOnvif.Event do
  @moduledoc """
  Interface for making requests to the Onvif event service

  https://www.onvif.org/ver10/events/wsdl/event.wsdl
  """

  import ExOnvif.Utils.ApiClient, only: [event_request: 4]
  import ExOnvif.Utils.XmlBuilder
  import SweetXml

  alias ExOnvif.Event.{EventProperties, PullPointSubscription, ServiceCapabilities}

  @doc """
  This method returns a PullPointSubscription that can be polled using PullMessages.

  This message contains the same elements as the SubscriptionRequest of the WS-BaseNotification without the ConsumerReference.

  If no Filter is specified the pullpoint notifies all occurring events to the client.
  """
  @spec create_pull_point_subscription(ExOnvif.Device.t(), String.t() | nil) ::
          {:ok, PullPointSubscription.t()} | {:error, any()}
  def create_pull_point_subscription(device, filter \\ nil) do
    filter_element =
      if filter do
        element(
          [],
          "TopicExpression",
          %{Dialect: "http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet"},
          filter
        )
      end

    body = element(:"tev:CreatePullPointSubscription", element(:"wsnt:Filter", filter_element))

    event_request(device, "CreatePullPointSubscription", body, &parse_pull_point_subscription/1)
  end

  @doc """
  Returns the event properties of the device, including the supported topic set with
  message descriptions for each topic.
  """
  @spec get_event_properties(ExOnvif.Device.t()) :: {:ok, ExOnvif.Event.EventProperties.t()}
  def get_event_properties(device) do
    event_request(
      device,
      "GetEventProperties",
      :"tev:GetEventProperties",
      &parse_event_properties/1
    )
  end

  @doc """
  Returns the capabilities of the event service.
  """
  @spec get_service_capabilities(ExOnvif.Device.t()) ::
          {:ok, ExOnvif.Event.ServiceCapabilities.t()}
  def get_service_capabilities(device) do
    event_request(
      device,
      "GetServiceCapabilities",
      :"tev:GetServiceCapabilities",
      &parse_service_capabilities/1
    )
  end

  defp parse_pull_point_subscription(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tev:CreatePullPointSubscriptionResponse"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tev", "http://www.onvif.org/ver10/events/wsdl")
    )
    |> PullPointSubscription.parse()
    |> PullPointSubscription.to_struct()
  end

  defp parse_service_capabilities(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tev:GetServiceCapabilitiesResponse/tev:Capabilities"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tev", "http://www.onvif.org/ver10/events/wsdl")
    )
    |> ServiceCapabilities.parse()
    |> ServiceCapabilities.to_struct()
  end

  defp parse_event_properties(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tev:GetEventPropertiesResponse"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tev", "http://www.onvif.org/ver10/events/wsdl")
      |> add_namespace("wsnt", "http://docs.oasis-open.org/wsn/bw-2")
    )
    |> EventProperties.parse()
    |> EventProperties.to_struct()
  end
end
