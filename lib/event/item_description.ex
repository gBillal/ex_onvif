defmodule ExOnvif.Event.ItemDescription do
  @moduledoc """
  Schema describing an item description within a topic's MessageDescription.

  Represents both `tt:SimpleItemDescription` (scalar values) and
  `tt:ElementItemDescription` (complex XML element values) from the ONVIF schema.
  The `kind` field distinguishes between the two.
  """

  use TypedEctoSchema

  import Ecto.Changeset
  import SweetXml

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :name, :string
    field :type, :string
    field :kind, Ecto.Enum, values: [:simple, :element]
  end

  def parse(entity) do
    tag = to_string(elem(entity, 1))
    kind = if String.ends_with?(tag, "SimpleItemDescription"), do: "simple", else: "element"

    %{
      name: xpath(entity, ~x"./@Name"s),
      type: xpath(entity, ~x"./@Type"s),
      kind: kind
    }
  end

  def changeset(struct, attrs) do
    cast(struct, attrs, [:name, :type, :kind])
  end
end
