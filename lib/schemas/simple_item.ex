defmodule Onvif.Schemas.SimpleItem do
  @moduledoc """
  Schema describing a simple item.
  """

  use TypedEctoSchema

  import Ecto.Changeset
  import SweetXml

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema null: false do
    field :name, :string
    field :value, :string
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def parse(doc) do
    xmap(
      doc,
      name: ~x"./@Name"s |> transform_by(&Macro.underscore/1),
      value: ~x"./@Value"s
    )
  end

  def changeset(struct, params) do
    cast(struct, params, [:name, :value])
  end
end
