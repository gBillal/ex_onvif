defmodule ExOnvif.Event.Messages do
  @moduledoc """
  Schema describing a pull messages response.
  """

  use TypedEctoSchema

  import Ecto.Changeset
  import SweetXml

  alias ExOnvif.Event.NotificationMessage

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema null: false do
    field :current_time, :utc_datetime
    field :termination_time, :utc_datetime

    embeds_many :notification_messages, NotificationMessage
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
      notification_messages:
        ~x"./wsnt:NotificationMessage"el |> transform_by(&parse_notification_messages/1)
    )
  end

  def changeset(pull_messages, attrs) do
    pull_messages
    |> cast(attrs, [:current_time, :termination_time])
    |> cast_embed(:notification_messages)
  end

  defp parse_notification_messages(doc) do
    Enum.map(List.wrap(doc), &NotificationMessage.parse/1)
  end
end
