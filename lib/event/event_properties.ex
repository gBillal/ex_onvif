defmodule ExOnvif.Event.EventProperties do
  @moduledoc """
  Schema describing Event Properties returned by GetEventProperties.
  """

  use TypedEctoSchema

  import Ecto.Changeset
  import SweetXml

  alias ExOnvif.Event.ItemDescription

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :topic_namespace_location, {:array, :string}
    field :fixed_topic_set, :boolean

    embeds_many :topic_sets, TopicSet, primary_key: false do
      @derive Jason.Encoder

      field :path, :string

      embeds_one :message_description, MessageDescription, primary_key: false do
        @derive Jason.Encoder

        field :is_property, :boolean
        embeds_many :source, ItemDescription
        embeds_many :key, ItemDescription
        embeds_many :data, ItemDescription
      end
    end

    field :topic_expression_dialect, {:array, :string}
    field :message_content_filter_dialect, {:array, :string}
    field :message_content_schema_location, {:array, :string}
    field :producer_properties_filter_dialect, {:array, :string}
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def parse(doc) do
    xmap(
      doc,
      topic_namespace_location: ~x"./tev:TopicNamespaceLocation/text()"sl,
      fixed_topic_set: ~x"./wsnt:FixedTopicSet/text()"s,
      topic_sets: ~x"./wstop:TopicSet/*"el |> transform_by(&parse_topic_set/1),
      topic_expression_dialect: ~x"./wsnt:TopicExpressionDialect/text()"sl,
      message_content_filter_dialect: ~x"./tev:MessageContentFilterDialect/text()"sl,
      message_content_schema_location: ~x"./tev:MessageContentSchemaLocation/text()"sl,
      producer_properties_filter_dialect: ~x"./tev:ProducerPropertiesFilterDialect/text()"sl
    )
  end

  def changeset(event_properties, attrs) do
    event_properties
    |> cast(
      attrs,
      __MODULE__.__schema__(:fields) -- [:topic_sets]
    )
    |> cast_embed(:topic_sets, with: &topic_set_changeset/2)
  end

  defp parse_topic_set(entity, path \\ []) do
    entity
    |> List.wrap()
    |> Enum.map(&do_parse_topic_set(&1, path))
    |> List.flatten()
  end

  defp do_parse_topic_set(entity, path) do
    name = to_string(elem(entity, 1))
    topic? = xpath(entity, ~x"./@wstop:topic"s |> transform_by(&String.to_existing_atom/1))

    if topic? do
      %{
        path: [name | path] |> Enum.reverse() |> Enum.join("/"),
        message_description: parse_message_description(entity)
      }
    else
      xpath(entity, ~x"./*"el |> transform_by(&parse_topic_set(&1, [name | path])))
    end
  end

  defp parse_message_description(entity) do
    result =
      xmap(
        entity,
        is_property:
          ~x"./tt:MessageDescription/@IsProperty"s
          |> add_namespace("tt", "http://www.onvif.org/ver10/schema"),
        source:
          ~x"./tt:MessageDescription/tt:Source/*"el
          |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
          |> transform_by(&parse_item_descriptions/1),
        key:
          ~x"./tt:MessageDescription/tt:Key/*"el
          |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
          |> transform_by(&parse_item_descriptions/1),
        data:
          ~x"./tt:MessageDescription/tt:Data/*"el
          |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
          |> transform_by(&parse_item_descriptions/1)
      )

    if result.is_property == "" and result.source == [] and result.key == [] and
         result.data == [] do
      nil
    else
      result
    end
  end

  defp parse_item_descriptions(entities) do
    Enum.map(List.wrap(entities), &ItemDescription.parse/1)
  end

  defp topic_set_changeset(topic_set, attrs) do
    topic_set
    |> cast(attrs, [:path])
    |> cast_embed(:message_description, with: &message_description_changeset/2)
  end

  defp message_description_changeset(message_description, attrs) do
    message_description
    |> cast(attrs, [:is_property])
    |> cast_embed(:source, with: &ItemDescription.changeset/2)
    |> cast_embed(:key, with: &ItemDescription.changeset/2)
    |> cast_embed(:data, with: &ItemDescription.changeset/2)
  end
end
