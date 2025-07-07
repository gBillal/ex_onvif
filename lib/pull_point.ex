defmodule ExOnvif.PullPoint do
  @moduledoc """
  Interface for making requests to the PullPoint service.
  """

  import ExOnvif.Utils.ApiClient, only: [pull_point_request: 5]
  import SweetXml
  import XmlBuilder

  alias ExOnvif.Event.Messages

  @doc """
  This method pulls one or more messages from a PullPoint.

  The device shall provide the following PullMessages command for all SubscriptionManager endpoints returned by the CreatePullPointSubscription command.
  This method shall not wait until the requested number of messages is available but return as soon as at least one message is available.

  The following options may be provided:
    * `timeout` - Timeout in seconds. Defaults to: 2
    * `message_limit` - The max number messages to retrieve from the pull point. Defaults to: 10
    * `subscription_id` - Subscription id to include as header in the soap request.
  """
  @spec pull_messages(
          device :: ExOnvif.Device.t(),
          url :: String.t(),
          opts :: Keyword.t()
        ) :: {:ok, Messages.t()} | {:error, any()}
  def pull_messages(device, url, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 2)
    message_limit = Keyword.get(opts, :message_limit, 10)
    subscription_id = Keyword.get(opts, :subscription_id)

    headers = if subscription_id, do: [subscription_id: subscription_id], else: []

    body =
      element(:"tev:PullMessages", [
        element(:"tev:Timeout", "PT#{timeout}S"),
        element(:"tev:MessageLimit", message_limit)
      ])

    pull_point_request(device, url, headers, body, &parse_pull_messages_response/1)
  end

  defp parse_pull_messages_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/tev:PullMessagesResponse"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      |> add_namespace("tev", "http://www.onvif.org/ver10/event/wsdl")
      |> add_namespace("wsnt", "http://docs.oasis-open.org/wsn/b-2")
    )
    |> Messages.parse()
    |> Messages.to_struct()
  end
end
