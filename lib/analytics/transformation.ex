defmodule Onvif.Analytics.Transformation do
  @moduledoc """
  Schema describing a transformation.
  """

  use TypedEctoSchema

  import Ecto.Changeset
  import SweetXml

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    embeds_one :translate, Translate, primary_key: false do
      @derive Jason.Encoder
      field :x, :float
      field :y, :float
    end

    embeds_one :scale, Scale, primary_key: false do
      @derive Jason.Encoder
      field :x, :float
      field :y, :float
    end
  end

  def parse(nil), do: nil

  def parse(doc) do
    xmap(
      doc,
      translate: ~x"./tt:Translate" |> transform_by(&parse_translate/1),
      scale: ~x"./tt:Scale" |> transform_by(&parse_translate/1)
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(transformation, attrs) do
    transformation
    |> cast(attrs, [])
    |> cast_embed(:translate, with: &scale_changeset/2)
    |> cast_embed(:scale, with: &scale_changeset/2)
  end

  defp parse_translate(doc) do
    xmap(
      doc,
      x: ~x"./@x"f,
      y: ~x"./@y"f
    )
  end

  def scale_changeset(scale, attrs) do
    cast(scale, attrs, [:x, :y])
  end
end
