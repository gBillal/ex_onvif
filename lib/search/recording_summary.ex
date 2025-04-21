defmodule Onvif.Search.RecordingSummary do
  @moduledoc """
  Schema describing recording summary.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:data_from, :utc_datetime)
    field(:data_until, :utc_datetime)
    field(:number_recordings, :integer)
  end

  def parse(doc) do
    xmap(
      doc,
      data_from: ~x"./tt:DataFrom/text()"s,
      data_until: ~x"./tt:DataUntil/text()"s,
      number_recordings: ~x"./tt:NumberRecordings/text()"s
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, __MODULE__.__schema__(:fields))
    |> validate_required([:data_from, :data_until, :number_recordings])
  end
end
