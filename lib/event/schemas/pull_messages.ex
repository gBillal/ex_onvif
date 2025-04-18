defmodule Onvif.Event.Schemas.PullMessages do
  @moduledoc """
  Scheme describing a pull messages response.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:current_time, :utc_datetime)
    field(:termination_time, :utc_datetime)

    embeds_many :notification_messages, NotificationMessage, primary_key: false do
      field(:topic, :string)

      embeds_one :message, Message, primary_key: false do
        @derive Jason.Encoder

        field(:utc_time, :utc_datetime)

        field(:property_operation, Ecto.Enum,
          values: [initialized: "Initialized", changed: "Changed", deleted: "Deleted"]
        )

        field(:data, :map)
        field(:source, :map)
      end
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
      current_time: ~x"./tev:CurrentTime/text()"s,
      termination_time: ~x"./tev:TerminationTime/text()"s,
      notification_messages: [
        ~x"./wsnt:NotificationMessage"el,
        topic: ~x"./wsnt:Topic/text()"s,
        message: [
          ~x"./wsnt:Message/tt:Message"e,
          utc_time: ~x"./@UtcTime"s,
          property_operation: ~x"./@PropertyOperation"s,
          data: ~x"./tt:Data"e |> transform_by(&parse_simple_items/1),
          source: ~x"./tt:Source"e |> transform_by(&parse_simple_items/1)
        ]
      ]
    )
  end

  def changeset(pull_messages, attrs) do
    pull_messages
    |> cast(attrs, [:current_time, :termination_time])
    |> cast_embed(:notification_messages, with: &notification_message_changeset/2)
  end

  defp parse_simple_items(nil), do: %{}

  defp parse_simple_items(doc) do
    xmap(
      doc,
      names: ~x"./tt:SimpleItem/@Name"sl,
      values: ~x"./tt:SimpleItem/@Value"sl
    )
    |> then(&Enum.zip(&1.names, &1.values))
    |> Map.new()
  end

  defp notification_message_changeset(notification_message, attrs) do
    notification_message
    |> cast(attrs, [:topic])
    |> cast_embed(:message,
      required: true,
      with: &message_changeset/2
    )
    |> validate_required([:topic])
  end

  defp message_changeset(message, attrs) do
    message
    |> cast(attrs, [:utc_time, :property_operation, :data, :source])
  end
end
