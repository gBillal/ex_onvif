defmodule Onvif.Media.AudioEncoderConfigurationOptions do
  @moduledoc """
  Optional configuration of the Audio encoder.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import SweetXml

  @required []
  @optional []

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    embeds_many :options, Options, primary_key: false, on_replace: :delete do
      @derive Jason.Encoder
      field(:encoding, Ecto.Enum, values: [G711: "G711", G726: "G726", AAC: "AAC"])

      field(:bitrates, {:array, :integer})
      field(:sample_rates, {:array, :integer})
    end
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      options: ~x"./tt:Options"elo |> transform_by(&parse_options/1)
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
    |> cast_embed(:options, with: &options_changeset/2)
  end

  defp parse_options(nil), do: nil
  defp parse_options([]), do: nil

  defp parse_options(docs) do
    Enum.map(docs, fn doc ->
      xmap(
        doc,
        encoding: ~x"./tt:Encoding/text()"so,
        bitrates: ~x"./tt:BitrateList/tt:Items/text()"sol,
        sample_rates: ~x"./tt:SampleRateList/tt:Items/text()"sol
      )
    end)
  end

  defp options_changeset(module, attrs) do
    cast(module, attrs, [:encoding, :bitrates, :sample_rates])
  end
end
