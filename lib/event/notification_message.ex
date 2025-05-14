defmodule Onvif.Event.NotificationMessage do
  @moduledoc """
  Scheme describing a notification message.
  """

  use TypedEctoSchema

  import Ecto.Changeset
  import SweetXml

  alias Onvif.Schemas.SimpleItem

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema null: false do
    field :topic, :string

    embeds_one :message, Message, primary_key: false do
      @derive Jason.Encoder

      field :utc_time, :utc_datetime_usec

      field :property_operation, Ecto.Enum,
        values: [initialized: "Initialized", changed: "Changed", deleted: "Deleted"]

      embeds_many :data, SimpleItem
      embeds_many :key, SimpleItem
      embeds_many :source, SimpleItem
    end
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def parse(doc) do
    xmap(
      doc,
      topic: ~x"./wsnt:Topic/text()"s,
      message: [
        ~x"./wsnt:Message/tt:Message"e,
        utc_time: ~x"./@UtcTime"s,
        property_operation: ~x"./@PropertyOperation"s,
        data: ~x"./tt:Data/tt:SimpleItem"el |> transform_by(&parse_simple_items/1),
        source: ~x"./tt:Source/tt:SimpleItem"el |> transform_by(&parse_simple_items/1),
        key: ~x"./tt:Key/tt:SimpleItem"el |> transform_by(&parse_simple_items/1)
      ]
    )
  end

  def changeset(notification_message, attrs) do
    notification_message
    |> cast(attrs, [:topic])
    |> cast_embed(:message,
      required: true,
      with: &message_changeset/2
    )
    |> validate_required([:topic])
  end

  defp parse_simple_items(doc) do
    Enum.map(List.wrap(doc), &SimpleItem.parse/1)
  end

  defp message_changeset(message, attrs) do
    message
    |> cast(attrs, [:utc_time, :property_operation])
    |> cast_embed(:data)
    |> cast_embed(:source)
    |> cast_embed(:key)
  end
end
