defmodule ExOnvif.Schemas.MetadataStream do
  @moduledoc """
  Schema describing metadata streams.
  """

  use TypedEctoSchema

  import Ecto.Changeset
  import SweetXml, except: [parse: 1]

  alias ExOnvif.Event.NotificationMessage

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    embeds_one :event, Event, primary_key: false do
      embeds_many :notification_messages, NotificationMessage
    end
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def parse(doc) when is_binary(doc) do
    doc
    |> SweetXml.parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//tt:MetadataStream"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
      |> add_namespace("wsnt", "http://docs.oasis-open.org/wsn/b-2")
    )
    |> parse()
  end

  def parse(nil), do: nil

  def parse(doc) do
    xmap(doc,
      event: ~x"./tt:Event"e |> transform_by(&parse_event/1)
    )
  end

  def changeset(metadata_stream, attrs) do
    metadata_stream
    |> cast(attrs, [])
    |> cast_embed(:event, with: &event_changeset/2)
  end

  defp parse_event(nil), do: nil

  defp parse_event(doc) do
    xmap(doc,
      notification_messages:
        ~x"./wsnt:NotificationMessage"el |> transform_by(&parse_notification_messages/1)
    )
  end

  defp parse_notification_messages(doc),
    do: Enum.map(List.wrap(doc), &NotificationMessage.parse/1)

  defp event_changeset(event, attrs) do
    event
    |> cast(attrs, [])
    |> cast_embed(:notification_messages)
  end
end
