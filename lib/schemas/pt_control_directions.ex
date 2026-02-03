defmodule ExOnvif.Schemas.PTControlDirection do
  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  embedded_schema do
    embeds_one :e_flip, EFlip, primary_key: false do
      field :mode, Ecto.Enum, values: [:OFF, :ON, :Extended]
    end

    embeds_one :reverse, Reverse, primary_key: false do
      field :mode, Ecto.Enum, values: [:OFF, :ON, :Extended]
    end
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [])
    |> cast_embed(:e_flip, with: &eflip_changeset/2, required: false)
    |> cast_embed(:reverse, with: &reverse_changeset/2, required: false)
  end

  defp eflip_changeset(schema, attrs) do
    schema
    |> cast(attrs, [:mode])
  end

  defp reverse_changeset(schema, attrs) do
    schema
    |> cast(attrs, [:mode])
  end

  def parse(nil), do: nil

  def parse(doc) do
    xmap(
      doc,
      e_flip: ~x"./tt:EFlip"e |> transform_by(&parse_eflip/1),
      reverse: ~x"./tt:Reverse"e |> transform_by(&parse_reverse/1)
    )
  end

  def parse_eflip(doc) do
    xmap(
      doc,
      mode: ~x"./tt:Mode/text()"s
    )
  end

  def parse_eflip(doc) do
    xmap(
      doc,
      mode: ~x"./tt:Mode/text()"s
    )
  end

  def parse_reverse(doc) do
    xmap(
      doc,
      mode: ~x"./tt:Mode/text()"s
    )
  end
end
