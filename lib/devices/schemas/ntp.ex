defmodule Onvif.Devices.Schemas.NTP do
  @moduledoc """
  Schema for the NTP configuration to be used with SetNTP and GetNTP operations.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml
  import XmlBuilder

  @required [:from_dhcp]
  @optional []

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:from_dhcp, :boolean)

    embeds_one :ntp_manual, NTPManual, primary_key: false, on_replace: :update do
      @derive Jason.Encoder
      field(:type, Ecto.Enum, values: [ipv4: "IPv4", ipv6: "IPv6", dns: "DNS"])
      field(:ipv4_address, :string)
      field(:ipv6_address, :string)
      field(:dns_name, :string)
    end

    embeds_one :ntp_from_dhcp, NTPFromDHCP, primary_key: false, on_replace: :update do
      @derive Jason.Encoder
      field(:type, Ecto.Enum, values: [ipv4: "IPv4", ipv6: "IPv6", dns: "DNS"])
      field(:ipv4_address, :string)
      field(:ipv6_address, :string)
      field(:dns_name, :string)
    end
  end

  def parse(nil), do: %{}
  def parse([]), do: %{}

  def parse(doc) do
    xmap(
      doc,
      from_dhcp: ~x"./tt:FromDHCP/text()"so,
      ntp_from_dhcp: ~x"./tt:NTPFromDHCP"eo |> transform_by(&parse_ntp_data/1),
      ntp_manual: ~x"./tt:NTPManual"eo |> transform_by(&parse_ntp_data/1)
    )
  end

  @doc """
  Encode to XML.
  """
  def encode(%__MODULE__{} = ntp) do
    [
      element(:"tds:FromDHCP", ntp.from_dhcp),
      ntp_manual_element(ntp) |> List.flatten()
    ]
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
    |> cast_embed(:ntp_from_dhcp, with: &ntp_data_changeset/2)
    |> cast_embed(:ntp_manual, with: &ntp_data_changeset/2)
  end

  defp ntp_data_changeset(module, attrs) do
    cast(module, attrs, [:type, :ipv4_address, :ipv6_address, :dns_name])
  end

  defp parse_ntp_data([]), do: nil
  defp parse_ntp_data(nil), do: nil

  defp parse_ntp_data(doc) do
    xmap(
      doc,
      type: ~x"./tt:Type/text()"so,
      ipv4_address: ~x"./tt:IPv4Address/text()"so,
      ipv6_address: ~x"./tt:IPv6Address/text()"so,
      dns_name: ~x"./tt:DNSname/text()"so
    )
  end

  defp ntp_manual_element(%__MODULE__{from_dhcp: true} = _ntp), do: []

  defp ntp_manual_element(%__MODULE__{from_dhcp: false} = ntp) do
    [element(:"tds:NTPManual", ntp_add_manual_element(ntp.ntp_manual))]
  end

  defp ntp_add_manual_element(ntp_manual) do
    [
      element(
        :"tt:Type",
        Keyword.fetch!(Ecto.Enum.mappings(ntp_manual.__struct__, :type), ntp_manual.type)
      ),
      ntp_manual_element_data(ntp_manual)
    ]
  end

  defp ntp_manual_element_data(%__MODULE__.NTPManual{type: :ipv4} = ntp_manual),
    do: element(:"tt:IPv4Address", ntp_manual.ipv4_address)

  defp ntp_manual_element_data(%__MODULE__.NTPManual{type: :ipv6} = ntp_manual),
    do: element(:"tt:IPv6Address", ntp_manual.ipv6_address)

  defp ntp_manual_element_data(%__MODULE__.NTPManual{type: :dns} = ntp_manual),
    do: element(:"tt:DNSname", ntp_manual.dns_name)
end
