defmodule Onvif.Event.Schemas.PullMessagesRequest do
  @moduledoc """
  This module defines the schema for the PullMessagesRequest.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import XmlBuilder

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:timeout, :integer, default: 5)
    field(:message_limit, :integer, default: 10)
    field(:subscription_id, :string)
  end

  def to_xml(%__MODULE__{timeout: timeout, message_limit: message_limit}) do
    element(:"tev:PullMessages", [
      element(:"tev:Timeout", "PT#{timeout}S"),
      element(:"tev:MessageLimit", message_limit)
    ])
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:timeout, :message_limit, :subscription_id])
    |> validate_required([:timeout, :message_limit])
    |> validate_number(:timeout, greater_than: 0)
    |> validate_number(:message_limit, greater_than: 0)
  end
end
