defmodule Onvif.Devices.Scope do
  @moduledoc """
  Scheme describing device scope.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:scope_def, Ecto.Enum, values: [fixed: "Fixed", configurable: "Configurable"])
    field(:scope_item, :string)
  end

  def parse(doc) do
    xmap(
      doc,
      scope_def: ~x"./tt:ScopeDef/text()"s,
      scope_item: ~x"./tt:ScopeItem/text()"s
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(scope, attrs) do
    scope
    |> cast(attrs, [:scope_def, :scope_item])
    |> validate_required([:scope_def, :scope_item])
  end
end
