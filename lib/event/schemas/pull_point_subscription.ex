defmodule Onvif.Event.Schemas.PullPointSubscription do
  @moduledoc """
  Schema describing a pull point subscription
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    embeds_one :subscription_reference, SubscriptionReference, primary_key: false do
      field(:address, :string)
    end

    field(:current_time, :utc_datetime)
    field(:termination_time, :utc_datetime)
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def parse(doc) do
    xmap(
      doc,
      current_time: ~x"./wsnt:CurrentTime/text()"s,
      termination_time: ~x"./wsnt:TerminationTime/text()"s,
      subscription_reference:
        ~x"./tev:SubscriptionReference"e |> transform_by(&parse_subscription_reference/1)
    )
  end

  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:current_time, :termination_time])
    |> cast_embed(:subscription_reference,
      required: true,
      with: &subscription_reference_changeset/2
    )
  end

  defp parse_subscription_reference(doc) do
    xmap(
      doc,
      address: ~x"./wsa:Address/text()"s
    )
  end

  defp subscription_reference_changeset(subscription_reference, attrs) do
    subscription_reference
    |> cast(attrs, [:address])
    |> validate_required([:address])
  end
end
