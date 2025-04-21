defmodule Onvif.Search.FindRecordings do
  @moduledoc """
  Module describing the FindRecordings schema.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Onvif.Utils.XmlBuilder

  alias Onvif.Search.SearchScope

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:max_matches, :integer)
    field(:keep_alive_time, :integer)

    embeds_one(:scope, SearchScope)
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def encode(%__MODULE__{} = schema) do
    element(
      :"tse:FindRecordings",
      [SearchScope.encode(schema.scope)]
      |> element("tse:MaxMatches", schema.max_matches)
      |> element("tse:KeepAliveTime", {:duration, schema.keep_alive_time})
    )
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [:max_matches, :keep_alive_time])
    |> validate_required([:keep_alive_time])
    |> cast_embed(:scope)
  end
end
