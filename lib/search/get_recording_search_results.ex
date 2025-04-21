defmodule Onvif.Search.GetRecordingSearchResults do
  @moduledoc """
  Module describing the request to `Onvif.Search.GetRecordingSearchResults`.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Onvif.Utils.XmlBuilder

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:search_token, :string)
    field(:min_results, :integer)
    field(:max_results, :integer)
    field(:wait_time, :integer)
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def encode(%__MODULE__{} = schema) do
    element(
      :"tse:GetRecordingSearchResults",
      element("tse:SearchToken", schema.search_token)
      |> element("tse:MinResults", schema.min_results)
      |> element("tse:MaxResults", schema.max_results)
      |> element("tse:WaitTime", {:duration, schema.wait_time})
    )
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, __MODULE__.__schema__(:fields))
    |> validate_required([:search_token])
  end
end
