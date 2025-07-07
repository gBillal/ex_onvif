defmodule ExOnvif.Search.FindRecordingResult do
  @moduledoc """
  A module describing results from `ExOnvif.Search.get_recording_search_results/2`.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  alias ExOnvif.Search.RecordingInformation

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:search_state, Ecto.Enum,
      values: [
        queued: "Queued",
        searching: "Searching",
        completed: "Completed",
        unknown: "Unknown"
      ]
    )

    embeds_many(:recording_information, RecordingInformation)
  end

  def parse(doc) do
    xmap(
      doc,
      search_state: ~x"./tt:SearchState/text()"s,
      recording_information:
        ~x"./tt:RecordingInformation"el |> transform_by(&RecordingInformation.parse/1)
    )
  end

  @spec to_struct(map()) :: {:error, Ecto.Changeset.t()} | {:ok, __MODULE__.t()}
  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  defp changeset(module, attrs) do
    module
    |> cast(attrs, [:search_state])
    |> cast_embed(:recording_information)
  end
end
