defmodule Onvif.Media.Profile.MulticastConfiguration do
  @moduledoc """
  MulticastConfiguration for Media Ver10
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Onvif.Utils.XmlBuilder
  import SweetXml

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:port, :integer)
    field(:ttl, :integer)
    field(:auto_start, :boolean)

    embeds_one :ip_address, IpAddress, primary_key: false, on_replace: :update do
      @derive Jason.Encoder
      field(:type, Ecto.Enum, values: [ipv4: "IPv4", ipv6: "IPv6"])
      field(:ipv4_address, :string)
      field(:ipv6_address, :string)
    end
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      port: ~x"./tt:Port/text()"i,
      ttl: ~x"./tt:TTL/text()"i,
      auto_start: ~x"./tt:AutoStart/text()"s,
      ip_address: ~x"./tt:Address"e |> transform_by(&parse_address/1)
    )
  end

  def encode(%__MODULE__{ip_address: %{type: :ipv4}} = multicast_configuration) do
    element(
      :"tt:Address",
      element(
        :"tt:Type",
        Keyword.fetch!(
          Ecto.Enum.mappings(multicast_configuration.ip_address.__struct__, :type),
          multicast_configuration.ip_address.type
        )
      )
      |> element(:"tt:IPv4Address", multicast_configuration.ip_address.ipv4_address)
    )
    |> element(:"tt:Port", multicast_configuration.port)
    |> element(:"tt:TTL", multicast_configuration.ttl)
    |> element(:"tt:AutoStart", multicast_configuration.auto_start)
  end

  def encode(%__MODULE__{ip_address: %{type: :ipv6}} = multicast_configuration) do
    element(
      :"tt:Address",
      element(
        :"tt:Type",
        Keyword.fetch!(
          Ecto.Enum.mappings(multicast_configuration.ip_address.__struct__, :type),
          multicast_configuration.ip_address.type
        )
      )
      |> element(:"tt:IPv6Address", multicast_configuration.ip_address.ipv6_address)
    )
    |> element(:"tt:Port", multicast_configuration.port)
    |> element(:"tt:TTL", multicast_configuration.ttl)
    |> element(:"tt:AutoStart", multicast_configuration.auto_start)
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [:port, :ttl, :auto_start])
    |> cast_embed(:ip_address, with: &ip_address_changeset/2)
  end

  defp parse_address(nil), do: nil
  defp parse_address([]), do: nil

  defp parse_address(doc) do
    xmap(
      doc,
      type: ~x"./tt:Type/text()"s,
      ipv4_address: ~x"./tt:IPv4Address/text()"s,
      ipv6_address: ~x"./tt:IPv6Address/text()"s
    )
  end

  defp ip_address_changeset(module, attrs) do
    cast(module, attrs, [:type, :ipv4_address, :ipv6_address])
  end
end
