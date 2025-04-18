defmodule Onvif.Event.Schemas.PullPointSubscription do
  @moduledoc """
  Schema describing a pull point subscription
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    embeds_one :subscription_reference, SubscriptionReference, primary_key: false do
      @derive Jason.Encoder
      field(:address, :string)

      embeds_one :reference_parameters, ReferenceParameters, primary_key: false do
        @derive Jason.Encoder
        field(:subscription_id, :string)
      end
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
      address:
        ~x"./wsa:Address/text()"s
        |> add_namespace("wsa", "http://schemas.xmlsoap.org/ws/2004/08/addressing")
        |> add_namespace("wsa", "http://www.w3.org/2005/08/addressing"),
      reference_parameters:
        ~x"./wsa5:ReferenceParameters"e |> transform_by(&parse_reference_parameters/1)
    )
  end

  defp parse_reference_parameters(nil), do: nil

  defp parse_reference_parameters(doc) do
    xmap(
      doc,
      subscription_id:
        ~x"./dom0:SubscriptionId/text()"s
        |> add_namespace("dom0", "http://www.axis.com/2009/event")
    )
  end

  defp subscription_reference_changeset(subscription_reference, attrs) do
    subscription_reference
    |> cast(attrs, [:address])
    |> validate_required([:address])
    |> cast_embed(:reference_parameters, with: &reference_parameters_changeset/2)
  end

  defp reference_parameters_changeset(reference_parameters, attrs) do
    cast(reference_parameters, attrs, [:subscription_id])
  end
end
