defmodule ExOnvif.Search.FindEvents do
  @moduledoc """
  Schema describing a find events request.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import ExOnvif.Utils.XmlBuilder

  alias ExOnvif.Search.SearchScope

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:start_point, :utc_datetime)
    field(:end_point, :utc_datetime)

    embeds_one(:search_scope, SearchScope)

    field(:include_start_state, :boolean, default: false)
    field(:max_matches, :integer)
    field(:keep_alive_time, :integer)
  end

  def encode(%__MODULE__{} = find_events) do
    element(
      "tse:FindEvents",
      element("tt:StartPoint", find_events.start_point)
      |> element("tt:EndPoint", find_events.end_point)
      |> element("tt:IncludeStartState", find_events.include_start_state)
      |> element("tt:MaxMatches", find_events.max_matches)
      |> element("tt:KeepAliveTime", {:duration, find_events.keep_alive_time})
      |> Kernel.++([SearchScope.encode(find_events.search_scope)])
    )
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [
      :start_point,
      :end_point,
      :include_start_state,
      :max_matches,
      :keep_alive_time
    ])
    |> cast_embed(:search_scope, with: &SearchScope.changeset/2)
  end
end
