defmodule Onvif.Analytics.Module do
  @moduledoc """
  Schema describing an analytics module.
  """

  use TypedEctoSchema

  import Ecto.Changeset
  import SweetXml

  alias Onvif.Analytics.Transformation
  alias Onvif.Schemas.SimpleItem

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :name, :string
    field :type, :string

    embeds_one :parameters, Parameters, primary_key: false do
      @derive Jason.Encoder

      embeds_many :simple_item, SimpleItem

      embeds_many :element_item, ElementItem, primary_key: false do
        @derive Jason.Encoder
        field(:name, :string)
        field(:content, :map)
      end
    end
  end

  def parse(doc) do
    xmap(
      doc,
      name: ~x"./@Name"s,
      type: ~x"./@Type"s,
      parameters: ~x"./tt:Parameters"e |> transform_by(&parse_parameters/1)
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [:name, :type])
    |> cast_embed(:parameters, with: &parameters_changeset/2)
  end

  defp parse_parameters([]), do: []

  defp parse_parameters(doc) do
    xmap(
      doc,
      simple_item: ~x"./tt:SimpleItem"el |> transform_by(&parse_simple_items/1),
      element_item: ~x"./tt:ElementItem"el |> transform_by(&parse_element_item/1)
    )
  end

  defp parse_simple_items(doc) do
    doc
    |> List.wrap()
    |> Enum.map(&SimpleItem.parse/1)
  end

  defp parse_element_item(nil), do: []
  defp parse_element_item([]), do: []

  defp parse_element_item([_ | _] = element_items),
    do: Enum.map(element_items, &parse_element_item/1)

  defp parse_element_item(doc) do
    element_item =
      xmap(
        doc,
        name: ~x"./@Name"s |> transform_by(&Macro.underscore/1),
        transformation: ~x"./tt:Transformation"e |> transform_by(&Transformation.parse/1)
      )

    cond do
      element_item[:transformation] ->
        %{name: element_item[:name], content: element_item[:transformation]}

      true ->
        %{name: element_item[:name], content: nil}
    end
  end

  defp parameters_changeset(module, attrs) do
    module
    |> cast(attrs, [])
    |> cast_embed(:simple_item)
    |> cast_embed(:element_item, with: &element_item_changeset/2)
  end

  defp element_item_changeset(module, attrs) do
    cast(module, attrs, [:name, :content])
  end
end
