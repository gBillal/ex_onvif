defmodule Onvif.Recording.RecordingJob do
  @moduledoc """
  Recordings.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import SweetXml

  alias Onvif.Recording.JobConfiguration

  @required [:job_token]
  @optional []

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:job_token, :string)

    embeds_one(:job_configuration, JobConfiguration)
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      job_token: ~x"./trc:JobToken/text()"so,
      job_configuration: ~x"./trc:JobConfiguration"eo |> transform_by(&JobConfiguration.parse/1)
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> cast_embed(:job_configuration, with: &JobConfiguration.changeset/2)
  end
end
